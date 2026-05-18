package pt.ipp.estg.election.aop

trait AuditLogAlg[F[_]] {
  def record(event: AuditEvent): F[Unit]
}
