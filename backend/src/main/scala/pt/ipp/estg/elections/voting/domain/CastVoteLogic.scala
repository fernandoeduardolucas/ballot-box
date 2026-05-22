package pt.ipp.estg.election.voting.domain

import java.time.Instant
import pt.ipp.estg.election.election.domain.{Election, Candidate}

object CastVoteLogic {

  def validate(
    election:  Election,
    candidate: Candidate,
    now:       Instant
  ): Either[VoteError, Unit] =
    for {
      _ <- Either.cond(
             !election.startDate.isAfter(now) && election.endDate.isAfter(now),
             (),
             ElectionNotActive: VoteError
           )
      _ <- Either.cond(
             candidate.electionId == election.id,
             (),
             CandidateNotInElection: VoteError
           )
    } yield ()
}
