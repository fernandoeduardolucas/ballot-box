package pt.ipp.estg.election.voting.application

import pt.ipp.estg.election.election.domain.ElectionId
import pt.ipp.estg.election.voting.domain.VoteCount
import java.util.UUID

trait GetVoteResultsAlg[F[_]] {
  def execute(electionId: UUID): F[List[VoteCount]]
}
