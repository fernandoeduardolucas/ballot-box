package pt.ipp.estg.election.voting.domain

import pt.ipp.estg.election.election.domain.ElectionId

trait VoteRepository[F[_]] {
  def save(vote: Vote): F[Either[VoteError, Unit]]
  def countByElection(electionId: ElectionId): F[List[VoteCount]]
}
