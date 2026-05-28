package pt.ipp.estg.election.aop

import cats.Monad
import cats.syntax.flatMap._
import cats.syntax.functor._
import fs2.concurrent.Topic

final class StreamingAuditLog[F[_]: Monad](
  target: AuditLogAlg[F],
  topic:  Topic[F, AuditEvent]
) extends AuditLogAlg[F] {

  def record(event: AuditEvent): F[Unit] =
    target.record(event) >> topic.publish1(event).void
}
