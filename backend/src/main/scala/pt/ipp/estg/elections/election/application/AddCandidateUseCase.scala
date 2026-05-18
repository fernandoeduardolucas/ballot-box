package pt.ipp.estg.election.election.application

import cats.data.EitherT
import cats.effect.Sync
import cats.syntax.functor._
import pt.ipp.estg.election.election.domain._

import java.time.Instant
import java.util.UUID

class AddCandidateUseCase[F[_]: Sync](
  electionRepo:  ElectionRepository[F],
  candidateRepo: CandidateRepository[F]
) extends AddCandidateAlg[F] {

  def execute(
    electionId: UUID,
    name:       String,
    party:      Option[String],
    photoUrl:   Option[String],
    number:     Int
  ): F[Either[CandidateError, Candidate]] = {
    val pipeline = for {
      election <- EitherT(
                    electionRepo
                      .findById(ElectionId(electionId))
                      .map(_.toRight(ElectionNotFound: CandidateError))
                  )
      now      <- EitherT.liftF(Sync[F].delay(Instant.now()))
      (cName, cParty, cPhoto, cNum) <- EitherT.fromEither[F](
                    AddCandidateLogic.validate(election, name, party, photoUrl, number, now)
                  )
      id       <- EitherT.liftF(Sync[F].delay(CandidateId(UUID.randomUUID())))
      candidate = Candidate(id, election.id, cName, cParty, cPhoto, cNum)
      _        <- EitherT.liftF(candidateRepo.save(candidate))
    } yield candidate
    pipeline.value
  }
}
