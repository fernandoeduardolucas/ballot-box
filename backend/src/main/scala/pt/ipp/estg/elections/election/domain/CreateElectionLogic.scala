package pt.ipp.estg.election.election.domain

import cats.Monad
import cats.data.EitherT
import cats.syntax.all._
import java.time.Instant

object CreateElectionLogic {

  def create[F[_]: Monad](
    title:           String,
    startDate:       Instant,
    endDate:         Instant,
    scopeRegionCode: Option[String] = None
  )(
    generateId: F[ElectionId]
  ): F[Either[ElectionError, Election]] = {
    val pipeline = for {
      (electionTitle, start, end, scope) <- EitherT.fromEither[F](Election.validate(title, startDate, endDate, scopeRegionCode))
      id                                <- EitherT.liftF(generateId)
    } yield Election(id, electionTitle, start, end, scope)
    pipeline.value
  }
}
