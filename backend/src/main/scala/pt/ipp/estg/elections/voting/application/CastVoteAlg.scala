package pt.ipp.estg.election.voting.application

import pt.ipp.estg.election.voting.domain.{Vote, VoteError}
import java.util.UUID

trait CastVoteAlg[F[_]] {
  def execute(
    voterId:     UUID,
    electionId:  UUID,
    candidateId: UUID,
    ip:          String
  ): F[Either[VoteError, Vote]]
}
