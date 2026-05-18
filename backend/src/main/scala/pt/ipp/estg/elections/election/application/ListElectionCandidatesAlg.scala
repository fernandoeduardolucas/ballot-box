package pt.ipp.estg.election.election.application

import pt.ipp.estg.election.election.domain.Candidate

import java.util.UUID

trait ListElectionCandidatesAlg[F[_]] {
  def execute(electionId: UUID): F[List[Candidate]]
}
