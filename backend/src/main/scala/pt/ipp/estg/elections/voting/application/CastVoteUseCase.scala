package pt.ipp.estg.election.voting.application

import cats.data.EitherT
import cats.effect.Sync
import cats.syntax.functor._
import pt.ipp.estg.election.election.domain.{CandidateId, ElectionId}
import pt.ipp.estg.election.election.domain.{CandidateRepository, ElectionRepository}
import pt.ipp.estg.election.identity.domain.VoterId
import pt.ipp.estg.election.voting.domain.{CastVoteLogic, Vote, VoteId, VoteError, VoteRepository}
import pt.ipp.estg.election.voting.domain.{ElectionNotActive, CandidateNotInElection}

import java.time.Instant
import java.util.UUID

class CastVoteUseCase[F[_]: Sync](
  electionRepo:  ElectionRepository[F],
  candidateRepo: CandidateRepository[F],
  voteRepo:      VoteRepository[F]
) extends CastVoteAlg[F] {

  def execute(
    voterId:     UUID,
    electionId:  UUID,
    candidateId: UUID,
    ip:          String
  ): F[Either[VoteError, Vote]] = {
    val pipeline = for {
      election   <- EitherT(
                      electionRepo
                        .findById(ElectionId(electionId))
                        .map(_.toRight(ElectionNotActive: VoteError))
                    )
      candidates <- EitherT.liftF(candidateRepo.findByElection(ElectionId(electionId)))
      candidate  <- EitherT.fromEither[F](
                      candidates
                        .find(_.id == CandidateId(candidateId))
                        .toRight(CandidateNotInElection: VoteError)
                    )
      now        <- EitherT.liftF(Sync[F].delay(Instant.now()))
      _          <- EitherT.fromEither[F](CastVoteLogic.validate(election, candidate, now))
      id         <- EitherT.liftF(Sync[F].delay(VoteId(UUID.randomUUID())))
      vote        = Vote(id, VoterId(voterId), ElectionId(electionId), CandidateId(candidateId), now)
      _          <- EitherT(voteRepo.save(vote))
    } yield vote
    pipeline.value
  }
}
