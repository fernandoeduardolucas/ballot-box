package pt.ipp.estg.election.election.domain

trait ElectionRepository[F[_]] {
  def save(election: Election): F[Unit]
  def findById(id: ElectionId): F[Option[Election]]
}
