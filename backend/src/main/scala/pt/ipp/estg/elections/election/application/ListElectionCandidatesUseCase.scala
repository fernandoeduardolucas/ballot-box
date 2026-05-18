package pt.ipp.estg.election.election.application

import cats.Monad
import pt.ipp.estg.election.election.domain.{Candidate, CandidateRepository, ElectionId}

import java.util.UUID

class ListElectionCandidatesUseCase[F[_]: Monad](repo: CandidateRepository[F]) extends ListElectionCandidatesAlg[F] {
  def execute(electionId: UUID): F[List[Candidate]] =
    repo.findByElection(ElectionId(electionId))
}
