package pt.ipp.estg.elections

import cats.effect.{IO, IOApp}
import com.comcast.ip4s.*
import doobie.Transactor
import org.http4s.ember.server.EmberServerBuilder
import org.http4s.server.middleware.{CORS, Logger}
import org.typelevel.log4cats.slf4j.Slf4jFactory
import pt.ipp.estg.elections.aop.LoggedElectionService
import pt.ipp.estg.elections.api.controllers.ElectionController
import pt.ipp.estg.elections.infra.{EventBus, PostgresRepository}
import pt.ipp.estg.elections.services.ElectionService

object Main extends IOApp.Simple:
  given Slf4jFactory[IO] = Slf4jFactory.create[IO]

  private val jdbcUrl = sys.env.getOrElse("DB_URL", "jdbc:postgresql://localhost:5432/elections")
  private val dbUser = sys.env.getOrElse("DB_USER", "elections")
  private val dbPassword = sys.env.getOrElse("DB_PASSWORD", "elections")

  def run: IO[Unit] =
    val transactor = Transactor.fromDriverManager[IO](
      driver = "org.postgresql.Driver",
      url = jdbcUrl,
      user = dbUser,
      password = dbPassword
    )

    for
      bus <- EventBus.create[IO]
      repo = PostgresRepository[IO](transactor)
      baseService = ElectionService[IO](repo, bus)
      service = LoggedElectionService[IO](baseService)
      controller = ElectionController[IO](service, repo, bus)
      serverIsRunning <- EmberServerBuilder.default[IO]
        .withHost(ipv4"0.0.0.0")
        .withPort(port"8080")
        .withHttpWebSocketApp(ws => CORS.policy(Logger.httpApp(true, true)(controller.routes(ws).orNotFound)))
        .build
        .useForever
    yield serverIsRunning
