package pt.ipp.estg.election.config

import pureconfig.generic.auto._
import pureconfig.ConfigSource

case class HttpConfig(host: String, port: Int)
case class GraphqlConfig(path: String)
case class AuditConfig(path: String)
case class WebsocketConfig(audit: AuditConfig)

case class AppSection(
  http: HttpConfig,
  graphql: GraphqlConfig,
  websocket: WebsocketConfig
)

case class DbConfig(url: String, user: String, password: String)

case class AppConfig(app: AppSection, db: DbConfig)

object AppConfig {
  def load(): AppConfig = {
    ConfigSource.default.loadOrThrow[AppConfig]
  }
}