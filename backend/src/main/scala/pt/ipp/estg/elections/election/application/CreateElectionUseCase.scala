package pt.ipp.estg.election.election.application

import cats.data.EitherT
import cats.effect.Sync
import pt.ipp.estg.election.election.domain._
import java.time.Instant
import java.util.UUID

class CreateElectionUseCase[F[_]: Sync](
  repository: ElectionRepository[F]
) extends CreateElectionAlg[F] {

  def execute(
    title:           String,
    startDate:       Instant,
    endDate:         Instant,
    scopeRegionCode: Option[String] = None
  ): F[Either[ElectionError, Election]] = {
    val generateId: F[ElectionId] = Sync[F].delay(ElectionId(UUID.randomUUID()))

    val pipeline = for {
      election <- EitherT(CreateElectionLogic.create[F](title, startDate, endDate, scopeRegionCode)(generateId))
      _        <- EitherT.liftF(repository.save(election))
    } yield election

    pipeline.value
  }
}
