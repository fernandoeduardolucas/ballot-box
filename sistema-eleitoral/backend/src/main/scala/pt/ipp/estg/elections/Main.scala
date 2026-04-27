package pt.ipp.estg.elections

import cats.effect.{IO, IOApp}
import com.comcast.ip4s.*
import org.http4s.ember.server.EmberServerBuilder
import org.http4s.server.middleware.{CORS, Logger}
import pt.ipp.estg.elections.api.Routes
import pt.ipp.estg.elections.domain.ElectionService
import pt.ipp.estg.elections.infra.{EventBus, InMemoryRepository}

object Main extends IOApp.Simple:
  def run: IO[Unit] =
    for
      repo <- InMemoryRepository.create[IO]
      bus <- EventBus.create[IO]
      service = ElectionService[IO](repo, bus)
      routes = Routes[IO](service, repo, bus)
      _ <- EmberServerBuilder.default[IO]
        .withHost(ipv4"0.0.0.0")
        .withPort(port"8080")
        .withHttpWebSocketApp(ws => CORS.policy(Logger.httpApp(true, true)(routes.http(ws).orNotFound)))
        .build
        .useForever
    yield ()
