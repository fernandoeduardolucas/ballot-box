package pt.ipp.estg.election.voting.infrastructure

import cats.effect.Concurrent
import cats.syntax.all._
import fs2.Stream
import fs2.concurrent.Topic
import pt.ipp.estg.election.election.domain.{CandidateId, ElectionId}

case class VoteCastEvent(electionId: ElectionId, candidateId: CandidateId)

trait VoteEventBus[F[_]] {
  def publish(event: VoteCastEvent): F[Unit]
  def subscribe: Stream[F, VoteCastEvent]
}

object VoteEventBus {
  def create[F[_]: Concurrent]: F[VoteEventBus[F]] =
    Topic[F, VoteCastEvent].map { topic =>
      new VoteEventBus[F] {
        def publish(event: VoteCastEvent): F[Unit] = topic.publish1(event).void
        def subscribe: Stream[F, VoteCastEvent]    = topic.subscribe(100)
      }
    }
}
