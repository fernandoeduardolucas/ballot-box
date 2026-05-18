package pt.ipp.estg.election.election.application

import pt.ipp.estg.election.election.domain.Election

trait ListAllElectionsAlg[F[_]] {
  def execute(): F[List[Election]]
}
