package pt.ipp.estg.election.voting.domain

import pt.ipp.estg.election.election.domain.ElectionId

import doobie.ConnectionIO

trait VoteRepository[F[_]] {
  def save(vote: Vote): ConnectionIO[Either[VoteError, Unit]]
  def countByElection(electionId: ElectionId): F[List[VoteCount]]
  def incrementCandidateTotal(candidateId: CandidateId): ConnectionIO[Unit]
}
