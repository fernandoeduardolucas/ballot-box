package pt.ipp.estg.election.config

import pureconfig.{ConfigReader, ConfigSource}
import pureconfig.generic.derivation.default._

case class HttpConfig(host: String, port: Int) derives ConfigReader
case class GraphqlConfig(path: String) derives ConfigReader
case class AuditConfig(path: String) derives ConfigReader
case class WebsocketConfig(audit: AuditConfig) derives ConfigReader

case class AppSection(
  http: HttpConfig,
  graphql: GraphqlConfig,
  websocket: WebsocketConfig
) derives ConfigReader

case class DbConfig(url: String, user: String, password: String) derives ConfigReader

case class AppConfig(app: AppSection, db: DbConfig) derives ConfigReader

object AppConfig {
  def load(): AppConfig = {
    ConfigSource.default.loadOrThrow[AppConfig]
  }
}