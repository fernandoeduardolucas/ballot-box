package pt.ipp.estg.elections

import cats.effect.{IO, IOApp}
import com.comcast.ip4s.*
import doobie.Transactor
import java.util.Properties
import org.http4s.ember.server.EmberServerBuilder
import org.http4s.server.middleware.{CORS, Logger}
import org.typelevel.log4cats.slf4j.Slf4jFactory
import pt.ipp.estg.elections.app.ElectionApplicationFacade
import pt.ipp.estg.elections.api.PlainTextAuditEventFrameEncoder
import pt.ipp.estg.elections.config.{AppConfig, ConfigProvider, PropertiesConfigProvider}
import pt.ipp.estg.elections.infra.{EventBus, PostgresRepositoryFactory}

/** Ponto de entrada da aplicação backend com bootstrap de dependências. */
object Main extends IOApp.Simple:
  given Slf4jFactory[IO] = Slf4jFactory.create[IO]

  // DIP: o entrypoint depende da abstração ConfigProvider.
  private val configProvider: ConfigProvider = PropertiesConfigProvider
  private val config: AppConfig = configProvider.load()

  // Cria infraestruturas e inicia o servidor HTTP/WebSocket.
  def run: IO[Unit] =
    val jdbcProps = Properties()
    jdbcProps.setProperty("user", config.dbUser)
    jdbcProps.setProperty("password", config.dbPassword)

    val transactor = Transactor.fromDriverManager[IO](
      driver = "org.postgresql.Driver",
      url = config.dbUrl,
      info = jdbcProps,
      logHandler = None
    )

    for
      bus <- EventBus.create[IO]
      repositoryFactory = PostgresRepositoryFactory[IO]()
      applicationFacade = ElectionApplicationFacade[IO](
        repositoryFactory,
        PlainTextAuditEventFrameEncoder,
        config
      )
      controller = applicationFacade.buildController(transactor, bus)
      serverIsRunning <- EmberServerBuilder.default[IO]
        .withHost(Host.fromString(config.httpHost).getOrElse(host"0.0.0.0"))
        .withPort(Port.fromInt(config.httpPort).getOrElse(port"8080"))
        .withHttpWebSocketApp(ws => CORS.policy(Logger.httpApp(true, true)(controller.routes(ws).orNotFound)))
        .build
        .useForever
    yield serverIsRunning
