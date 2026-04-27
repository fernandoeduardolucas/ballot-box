package pt.ipp.estg.elections.infra

import cats.effect.kernel.Async
import cats.effect.std.Queue
import cats.syntax.all.*
import fs2.Stream
import pt.ipp.estg.elections.domain.*

final class EventBus[F[_]: Async](queue: Queue[F, AuditEvent]) extends EventPublisher[F]:
  def publish(event: AuditEvent): F[Unit] = queue.offer(event)
  def stream: Stream[F, AuditEvent] = Stream.fromQueueUnterminated(queue)

object EventBus:
  def create[F[_]: Async]: F[EventBus[F]] =
    Queue
      .unbounded[F, AuditEvent]
      .map(queue => new EventBus[F](queue))
