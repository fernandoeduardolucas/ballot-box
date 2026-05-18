package pt.ipp.estg.election.election.application

import cats.Monad
import pt.ipp.estg.election.election.domain.{Election, ElectionRepository}

class ListAllElectionsUseCase[F[_]: Monad](repo: ElectionRepository[F]) extends ListAllElectionsAlg[F] {
  def execute(): F[List[Election]] = repo.findAll()
}
