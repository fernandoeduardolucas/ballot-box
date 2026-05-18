package pt.ipp.estg.election.election.domain

trait CandidateRepository[F[_]] {
  def save(candidate: Candidate): F[Unit]
  def findByElection(electionId: ElectionId): F[List[Candidate]]
}
