package pt.ipp.estg.election.identity.infrastructure

import cats.effect.MonadCancelThrow
import cats.syntax.functor._
import doobie._
import doobie.implicits._
import pt.ipp.estg.election.aop.{AuditEvent, AuditLogAlg}

class DoobieAuditLogRepository[F[_]: MonadCancelThrow](xa: Transactor[F]) extends AuditLogAlg[F] {

  def record(event: AuditEvent): F[Unit] =
    sql"""
      INSERT INTO audit_log (event_type, civil_id, ip, success, reason)
      VALUES (${event.eventType}, ${event.civilId}, ${event.ip}, ${event.success}, ${event.reason})
    """.update.run.transact(xa).void
}
