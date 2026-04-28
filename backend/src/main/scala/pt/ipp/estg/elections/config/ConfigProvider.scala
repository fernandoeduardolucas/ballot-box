package pt.ipp.estg.elections.config

/** DIP: consumidores dependem desta abstração, não da implementação concreta. */
trait ConfigProvider:
  def load(): AppConfig

/** Implementação por omissão baseada em `application.properties` + env. */
object PropertiesConfigProvider extends ConfigProvider:
  override def load(): AppConfig = AppConfig.load()
