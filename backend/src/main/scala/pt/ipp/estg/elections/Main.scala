package pt.ipp.estg.election

import cats.effect._
import com.comcast.ip4s._
import doobie.util.transactor.Transactor
import io.circe.Json
import org.http4s._
import org.http4s.circe._
import org.http4s.dsl.io._
import org.http4s.ember.server.EmberServerBuilder
import org.http4s.implicits._
import org.http4s.server.Router
import pt.ipp.estg.election.config.AppConfig
import pt.ipp.estg.election.api.graphql.{ElectionContext, MutationType}
import pt.ipp.estg.election.identity.application.RegisterVoterUseCase
import pt.ipp.estg.election.identity.infrastructure.{BcryptPasswordHasher, DoobieVoterRepository}
import sangria.execution.Executor
import sangria.marshalling.circe._
import sangria.parser.QueryParser
import sangria.schema._
import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}

object Main extends IOApp.Simple {

  val config: AppConfig = AppConfig.load()

  private val QueryType: ObjectType[ElectionContext, Unit] = ObjectType(
    "Query",
    fields[ElectionContext, Unit](
      Field(
        name = "health",
        fieldType = StringType,
        resolve = _ => "ok"
      )
    )
  )

  val schema = Schema(
    query = QueryType,
    mutation = Some(MutationType.Mutation)
  )

  val transactor: Transactor[IO] = Transactor.fromDriverManager[IO](
    "org.postgresql.Driver",
    config.db.url,
    config.db.user,
    config.db.password,
    None
  )

  val voterRepo = new DoobieVoterRepository[IO](transactor)
  val hasher = new BcryptPasswordHasher[IO]
  val registerUseCase = new RegisterVoterUseCase[IO](voterRepo, hasher)
  val graphqlContext = ElectionContext(registerUseCase)

  private val graphqlRoutePath = config.app.graphql.path.stripPrefix("/")

  def graphqlRoutes: HttpRoutes[IO] = HttpRoutes.of[IO] {
    case req @ POST -> Root / path if path == graphqlRoutePath =>
      req.as[Json].flatMap { body =>
        val query = body.hcursor.get[String]("query").getOrElse("")
        
        QueryParser.parse(query) match {
          case Success(ast) =>
            IO.fromFuture(IO(
              Executor.execute(
                schema = schema,
                queryAst = ast,
                userContext = graphqlContext
              )
            )).flatMap(res => Ok(res))
              .handleErrorWith(e => BadRequest(Json.obj("error" -> Json.fromString(e.getMessage))))

          case Failure(error) =>
            BadRequest(Json.obj("error" -> Json.fromString(error.getMessage)))
        }
      }
  }

  def run: IO[Unit] = {
    val httpApp = Router("/" -> graphqlRoutes).orNotFound

    val host = Host.fromString(config.app.http.host).getOrElse(host"0.0.0.0")
    val port = Port.fromInt(config.app.http.port).getOrElse(port"8080")

    EmberServerBuilder
      .default[IO]
      .withHost(host)
      .withPort(port)
      .withHttpApp(httpApp)
      .build
      .use(_ => IO.println(s"Servidor a correr em $host:$port${config.app.graphql.path}...") *> IO.never)
  }
}