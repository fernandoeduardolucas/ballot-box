package pt.ipp.estg.election.voting.application

import cats.effect.IO
import doobie.util.transactor.Transactor
import doobie.implicits._
import pt.ipp.estg.election.voting.domain.VoteRepository
import pt.ipp.estg.election.voting.infrastructure.VoteEventBus

object VoteConsumer {
  def startConsumer(eventBus: VoteEventBus[IO], repo: VoteRepository[IO], xa: Transactor[IO]): IO[Unit] = {
    eventBus.subscribe
      .evalMap { event =>
        // 1. Incrementa o voto na DB de forma transacional
        repo.incrementCandidateTotal(event.candidateId).transact(xa)
      }
      .compile.drain // Consome a stream até ao infinito
  }
}
