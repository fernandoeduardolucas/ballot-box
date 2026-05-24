package pt.ipp.estg.election

import cats.effect._
import cats.effect.std.Dispatcher
import com.comcast.ip4s._
import doobie.util.transactor.Transactor
import java.util.Properties
import io.circe.Json
import org.flywaydb.core.Flyway
import org.http4s._
import org.http4s.circe._
import org.http4s.dsl.io._
import org.http4s.ember.server.EmberServerBuilder
import org.http4s.implicits._
import org.http4s.server.Router
import org.http4s.server.middleware.CORS
import org.typelevel.ci.CIString
import org.typelevel.log4cats.LoggerFactory
import org.typelevel.log4cats.slf4j.{Slf4jFactory, Slf4jLogger}
import pt.ipp.estg.election.aop.{AuditedCastVoteUseCase, AuditedLoginUseCase, AuditedRegisterVoterUseCase, LoggedRegisterVoterUseCase}
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
import pt.ipp.estg.election.voting.infrastructure.VoteEventBus
import pt.ipp.estg.election.voting.application.VoteConsumer
import fs2.Pipe
import fs2.Stream
import io.circe.syntax._
import io.circe.generic.auto._
import org.http4s.server.websocket.WebSocketBuilder2
import org.http4s.websocket.WebSocketFrame
import cats.syntax.all._

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
    val auditedLogin     = new AuditedLoginUseCase[IO](baseLoginUseCase, auditLogRepo)

    val tokenVerifier     = new JwtTokenVerifier[IO](config.security.jwt.secret)

    val electionRepo            = new DoobieElectionRepository[IO](transactor)
    val candidateRepo           = new DoobieCandidateRepository[IO](transactor)
    val createElection          = new CreateElectionUseCase[IO](electionRepo)
    val addCandidate            = new AddCandidateUseCase[IO](electionRepo, candidateRepo)
    val listActiveElections     = new ListActiveElectionsUseCase[IO](electionRepo)
    val listAllElections        = new ListAllElectionsUseCase[IO](electionRepo)
    val listElectionCandidates  = new ListElectionCandidatesUseCase[IO](candidateRepo)

    val voteRepo       = new DoobieVoteRepository[IO](transactor)
    val getVoteResults = new GetVoteResultsUseCase[IO](voteRepo)

    val schema = Schema(
      query    = QueryType.Query,
      mutation = Some(MutationType.Mutation)
    )

    val host        = Host.fromString(config.app.http.host).getOrElse(host"0.0.0.0")
    val port        = Port.fromInt(config.app.http.port).getOrElse(port"8080")
    val graphqlPath = config.app.graphql.path.stripPrefix("/")

    runMigrations(config) *> (for {
      eventBus   <- Resource.eval(VoteEventBus.create[IO])
      _          <- VoteConsumer.startConsumer(eventBus, voteRepo, transactor).background
      dispatcher <- Dispatcher.parallel[IO]
      _ <- {
        val baseCastVote = new CastVoteUseCase[IO](electionRepo, candidateRepo, voteRepo, eventBus, transactor)
        val castVote     = new AuditedCastVoteUseCase[IO](baseCastVote, auditLogRepo)

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

        def webSocketRoute(wsb: WebSocketBuilder2[IO]): HttpRoutes[IO] = HttpRoutes.of[IO] {
          case GET -> Root / "audit" / "stream" =>
            import pt.ipp.estg.election.election.domain.{ElectionId, CandidateId}
            implicit val encodeElectionId: io.circe.Encoder[ElectionId] = io.circe.Encoder.encodeUUID.contramap(_.value)
            implicit val encodeCandidateId: io.circe.Encoder[CandidateId] = io.circe.Encoder.encodeUUID.contramap(_.value)
            
            val toClient: Stream[IO, WebSocketFrame] =
              eventBus.subscribe.map(event => WebSocketFrame.Text(event.asJson.noSpaces))
            val fromClient: Pipe[IO, WebSocketFrame, Unit] = _.evalMap(_ => IO.unit)
            wsb.build(toClient, fromClient)
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
              .httpApp(Router("/" -> (graphqlRoutes <+> webSocketRoute(wsb))).orNotFound)
          )
          .build
      }
    } yield ()).use(_ => IO.println(s"Servidor a correr em $host:$port/$graphqlPath...") *> IO.never)
  }
}
