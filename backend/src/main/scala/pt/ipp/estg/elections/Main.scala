package pt.ipp.estg.election

import cats.effect._
import cats.effect.std.Dispatcher
import cats.syntax.all._
import com.comcast.ip4s._
import doobie.util.transactor.Transactor
import fs2.concurrent.Topic
import java.util.Properties
import io.circe.Json
import io.circe.syntax._
import org.flywaydb.core.Flyway
import org.http4s._
import org.http4s.circe._
import org.http4s.dsl.io._
import org.http4s.ember.server.EmberServerBuilder
import org.http4s.implicits._
import org.http4s.server.Router
import org.http4s.server.middleware.CORS
import org.http4s.server.websocket.WebSocketBuilder2
import org.http4s.websocket.WebSocketFrame
import org.typelevel.ci.CIString
import org.typelevel.log4cats.LoggerFactory
import org.typelevel.log4cats.slf4j.{Slf4jFactory, Slf4jLogger}
import pt.ipp.estg.election.aop.{AuditEvent, AuditedCastVoteUseCase, AuditedLoginUseCase, AuditedRegisterVoterUseCase, LoggedRegisterVoterUseCase, StreamingAuditLog}
import pt.ipp.estg.election.api.graphql.{ElectionContext, MutationType, QueryType}
import pt.ipp.estg.election.config.AppConfig
import pt.ipp.estg.election.election.application.{AddCandidateUseCase, CreateElectionUseCase, ListActiveElectionsUseCase, ListAllElectionsUseCase, ListElectionCandidatesUseCase}
import pt.ipp.estg.election.election.infrastructure.{DoobieCandidateRepository, DoobieElectionRepository}
import pt.ipp.estg.election.voting.application.{CastVoteUseCase, GetVoteResultsUseCase}
import pt.ipp.estg.election.voting.infrastructure.DoobieVoteRepository
import pt.ipp.estg.election.identity.application.{LoginVoterUseCase, RegisterVoterUseCase}
import pt.ipp.estg.election.identity.domain.AuthenticatedVoter
import pt.ipp.estg.election.identity.infrastructure._
import sangria.execution.Executor
import sangria.marshalling.circe._
import sangria.parser.QueryParser
import sangria.schema._

import scala.concurrent.ExecutionContext
import scala.util.{Failure, Success}

object Main extends IOApp.Simple {

  private def runMigrations(config: AppConfig): IO[Unit] =
    IO.delay {
      Flyway
        .configure()
        .dataSource(config.db.url, config.db.user, config.db.password)
        .load()
        .migrate()
    }.void

  private def extractIp(req: Request[IO]): String =
    req.headers
      .get(CIString("X-Forwarded-For"))
      .map(_.head.value.split(",").head.trim)
      .orElse(req.headers.get(CIString("X-Real-Ip")).map(_.head.value))
      .getOrElse("unknown")

  private def extractBearerToken(req: Request[IO]): Option[String] =
    req.headers
      .get(CIString("Authorization"))
      .map(_.head.value)
      .filter(_.startsWith("Bearer "))
      .map(_.drop(7).trim)

  private def extractWebSocketToken(req: Request[IO]): Option[String] =
    extractBearerToken(req)
      .orElse(req.params.get("token").map(_.trim).filter(_.nonEmpty))

  def run: IO[Unit] = {
    val config = AppConfig.load()

    given LoggerFactory[IO] = Slf4jFactory.create[IO]
    given ExecutionContext   = ExecutionContext.global

    val dbProps = {
      val p = new Properties()
      p.setProperty("user", config.db.user)
      p.setProperty("password", config.db.password)
      p
    }
    val transactor = Transactor.fromDriverManager[IO](
      "org.postgresql.Driver",
      config.db.url,
      dbProps,
      None
    )

    val voterRepo      = new DoobieVoterRepository[IO](transactor)
    val auditLogRepo   = new DoobieAuditLogRepository[IO](transactor)
    val hasher         = new BcryptPasswordHasher[IO]
    val verifier       = new BcryptPasswordVerifier[IO]
    val tokenGenerator = new JwtTokenGenerator[IO](
      config.security.jwt.secret,
      config.security.jwt.expirationSeconds
    )

    val baseRegisterUseCase = new RegisterVoterUseCase[IO](voterRepo, hasher)
    val auditedRegister     = new AuditedRegisterVoterUseCase[IO](
      baseRegisterUseCase,
      Slf4jLogger.getLoggerFromName[IO]("audit.identity.register")
    )
    val loggedRegister = new LoggedRegisterVoterUseCase[IO](auditedRegister)

    val baseLoginUseCase = new LoginVoterUseCase[IO](voterRepo, verifier, tokenGenerator)

    val tokenVerifier     = new JwtTokenVerifier[IO](config.security.jwt.secret)

    val electionRepo            = new DoobieElectionRepository[IO](transactor)
    val candidateRepo           = new DoobieCandidateRepository[IO](transactor)
    val createElection          = new CreateElectionUseCase[IO](electionRepo)
    val addCandidate            = new AddCandidateUseCase[IO](electionRepo, candidateRepo)
    val listActiveElections     = new ListActiveElectionsUseCase[IO](electionRepo)
    val listAllElections        = new ListAllElectionsUseCase[IO](electionRepo)
    val listElectionCandidates  = new ListElectionCandidatesUseCase[IO](candidateRepo)

    val voteRepo       = new DoobieVoteRepository[IO](transactor)
    val baseCastVote   = new CastVoteUseCase[IO](electionRepo, candidateRepo, voteRepo)
    val getVoteResults = new GetVoteResultsUseCase[IO](voteRepo)

    val schema = Schema(
      query    = QueryType.Query,
      mutation = Some(MutationType.Mutation)
    )

    val host        = Host.fromString(config.app.http.host).getOrElse(host"0.0.0.0")
    val port        = Port.fromInt(config.app.http.port).getOrElse(port"8080")
    val graphqlPath = config.app.graphql.path.stripPrefix("/")

    runMigrations(config) *> (for {
      auditTopic <- Resource.eval(Topic[IO, AuditEvent])
      dispatcher <- Dispatcher.parallel[IO]
      _ <- {
        val streamingAuditLog = new StreamingAuditLog[IO](auditLogRepo, auditTopic)
        val auditedLogin      = new AuditedLoginUseCase[IO](baseLoginUseCase, streamingAuditLog)
        val castVote          = new AuditedCastVoteUseCase[IO](baseCastVote, streamingAuditLog)

        def graphqlRoutes: HttpRoutes[IO] = HttpRoutes.of[IO] {
          case req @ POST -> Root / `graphqlPath` =>
            val ip       = extractIp(req)
            val rawToken = extractBearerToken(req)
            for {
              authedVoter <- rawToken.fold(IO.pure(Option.empty[AuthenticatedVoter]))(tokenVerifier.verify)
              context      = ElectionContext(loggedRegister, auditedLogin, createElection, addCandidate, listActiveElections, listAllElections, listElectionCandidates, castVote, getVoteResults, authedVoter, dispatcher, ip)
              response    <- req.as[Json].flatMap { body =>
                val query     = body.hcursor.get[String]("query").getOrElse("")
                val variables = body.hcursor.get[Json]("variables").getOrElse(Json.obj())
                QueryParser.parse(query) match {
                  case Success(ast) =>
                    IO.fromFuture(IO(
                      Executor.execute(schema = schema, queryAst = ast, userContext = context, variables = variables)
                    )).flatMap(res => Ok(res))
                      .handleErrorWith(e => BadRequest(Json.obj("error" -> Json.fromString(e.getMessage))))
                  case Failure(error) =>
                    BadRequest(Json.obj("error" -> Json.fromString(error.getMessage)))
                }
              }
            } yield response
        }

        def auditRoutes(wsb: WebSocketBuilder2[IO]): HttpRoutes[IO] = HttpRoutes.of[IO] {
          case req @ GET -> Root / "admin" / "audit" / "stream" =>
            extractWebSocketToken(req) match {
              case None =>
                Forbidden("Token de administracao em falta.")
              case Some(rawToken) =>
                tokenVerifier.verify(rawToken).flatMap {
                  case Some(voter) if voter.isAdmin =>
                    val toClient = auditTopic
                      .subscribe(256)
                      .map(event => WebSocketFrame.Text(event.asJson.noSpaces))

                    wsb.build(toClient, _.void)
                  case _ =>
                    Forbidden("Acesso restrito a administradores.")
                }
            }
        }

        EmberServerBuilder
          .default[IO]
          .withHost(host)
          .withPort(port)
          .withHttpWebSocketApp(wsb =>
            CORS.policy
              .withAllowOriginAll
              .withAllowMethodsAll
              .withAllowHeadersAll
              .httpApp(Router("/" -> (graphqlRoutes <+> auditRoutes(wsb))).orNotFound)
          )
          .build
      }
    } yield ()).use(_ => IO.println(s"Servidor a correr em $host:$port/$graphqlPath...") *> IO.never)
  }
}
