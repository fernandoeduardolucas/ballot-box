package pt.ipp.estg.election.voting.domain

import java.time.Instant
import pt.ipp.estg.election.election.domain.{Candidate, Election, ElectionState}

object CastVoteLogic {

  def validate(
    election:  Election,
    candidate: Candidate,
    now:       Instant
  ): Either[VoteError, Unit] =
    // The State object decides whether voting is currently open.
    val state = ElectionState.from(election, now)
    for {
      _ <- Either.cond(
             state.allowsVoting,
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
