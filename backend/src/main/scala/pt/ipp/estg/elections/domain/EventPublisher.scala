package pt.ipp.estg.elections.domain

/** Porta de saída para publicação de eventos de auditoria. */
trait EventPublisher[F[_]]:
  /** Publica um evento para consumidores assíncronos. */
  def publish(event: AuditEvent): F[Unit]
