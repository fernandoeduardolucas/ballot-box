package pt.ipp.estg.elections

import cats.effect.{IO, IOApp}
import com.comcast.ip4s.*
import org.http4s.ember.server.EmberServerBuilder
import org.http4s.server.middleware.{CORS, Logger}
import org.typelevel.log4cats.slf4j.Slf4jFactory
import pt.ipp.estg.elections.aop.LoggedElectionService
import pt.ipp.estg.elections.api.Routes
import pt.ipp.estg.elections.domain.ElectionService
import pt.ipp.estg.elections.infra.{EventBus, InMemoryRepository}

object Main extends IOApp.Simple:
  given Slf4jFactory[IO] = Slf4jFactory.create[IO]

  def run: IO[Unit] =
    for
      repo <- InMemoryRepository.create[IO]
      bus <- EventBus.create[IO]
      baseService = ElectionService[IO](repo, bus)
      service = LoggedElectionService[IO](baseService)
      routes = Routes[IO](service, repo, bus)
      _ <- EmberServerBuilder.default[IO]
        .withHost(ipv4"0.0.0.0")
        .withPort(port"8080")
        .withHttpWebSocketApp(ws => CORS.policy(Logger.httpApp(true, true)(routes.http(ws).orNotFound)))
        .build
        .useForever
    yield ()
