package pt.ipp.estg.elections.config

import java.io.InputStream
import java.util.Properties

/** Configuração tipada da aplicação. */
final case class AppConfig(
  httpHost: String,
  httpPort: Int,
  graphqlPath: String,
  auditWebSocketPath: String,
  dbUrl: String,
  dbUser: String,
  dbPassword: String
)

object AppConfig:
  private val defaultConfig = AppConfig(
    httpHost = "0.0.0.0",
    httpPort = 8080,
    graphqlPath = "/graphql",
    auditWebSocketPath = "/audit/stream",
    dbUrl = "jdbc:postgresql://localhost:5432/elections",
    dbUser = "elections",
    dbPassword = "elections"
  )

  /** Carrega configuração de `application.properties` e aplica overrides de ambiente. */
  def load(): AppConfig =
    val properties = Properties()
    val resourceName = "application.properties"
    val resourceStream: InputStream | Null = getClass.getClassLoader.getResourceAsStream(resourceName)

    if resourceStream != null then
      val stream = resourceStream.asInstanceOf[InputStream]
      try properties.load(stream)
      finally stream.close()

    val filePortValue = properties.getProperty("app.http.port", defaultConfig.httpPort.toString)
    val parsedFilePort = filePortValue.toIntOption.getOrElse(defaultConfig.httpPort)

    val configFromProperties = AppConfig(
      httpHost = properties.getProperty("app.http.host", defaultConfig.httpHost),
      httpPort = parsedFilePort,
      graphqlPath = normalizePath(properties.getProperty("app.graphql.path", defaultConfig.graphqlPath)),
      auditWebSocketPath = normalizePath(properties.getProperty("app.websocket.audit.path", defaultConfig.auditWebSocketPath)),
      dbUrl = properties.getProperty("db.url", defaultConfig.dbUrl),
      dbUser = properties.getProperty("db.user", defaultConfig.dbUser),
      dbPassword = properties.getProperty("db.password", defaultConfig.dbPassword)
    )

    configFromProperties.copy(
      httpHost = sys.env.getOrElse("APP_HOST", configFromProperties.httpHost),
      httpPort = sys.env
        .get("APP_PORT")
        .flatMap(port => port.toIntOption)
        .getOrElse(configFromProperties.httpPort),
      graphqlPath = normalizePath(sys.env.getOrElse("GRAPHQL_PATH", configFromProperties.graphqlPath)),
      auditWebSocketPath = normalizePath(sys.env.getOrElse("AUDIT_WS_PATH", configFromProperties.auditWebSocketPath)),
      dbUrl = sys.env.getOrElse("DB_URL", configFromProperties.dbUrl),
      dbUser = sys.env.getOrElse("DB_USER", configFromProperties.dbUser),
      dbPassword = sys.env.getOrElse("DB_PASSWORD", configFromProperties.dbPassword)
    )

  private def normalizePath(path: String): String =
    if path.startsWith("/") then path else s"/$path"
