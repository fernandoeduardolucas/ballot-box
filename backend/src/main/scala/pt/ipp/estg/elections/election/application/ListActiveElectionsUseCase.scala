package pt.ipp.estg.election.election.application

import cats.effect.kernel.Sync
import cats.syntax.flatMap._
import pt.ipp.estg.election.election.domain.{Election, ElectionRepository}

class ListActiveElectionsUseCase[F[_]: Sync](repo: ElectionRepository[F])
    extends ListActiveElectionsAlg[F] {

  override def execute(): F[List[Election]] =
    Sync[F].delay(java.time.Instant.now()).flatMap(repo.findActive)
}
