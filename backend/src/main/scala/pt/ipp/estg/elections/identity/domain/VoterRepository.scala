package pt.ipp.estg.election.identity.domain

trait VoterRepository[F[_]] {
  def checkExists(civilId: CivilId): F[Boolean]
  def save(voter: Voter): F[Unit]
}