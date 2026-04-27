package pt.ipp.estg.elections.domain

trait EventPublisher[F[_]]:
  def publish(event: AuditEvent): F[Unit]
