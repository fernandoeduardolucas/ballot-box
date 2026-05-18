package pt.ipp.estg.election.election.application

import pt.ipp.estg.election.election.domain.Election

trait ListActiveElectionsAlg[F[_]] {
  def execute(): F[List[Election]]
}
