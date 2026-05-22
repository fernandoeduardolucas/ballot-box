package pt.ipp.estg.election.voting.application

import pt.ipp.estg.election.election.domain.ElectionId
import pt.ipp.estg.election.voting.domain.{VoteCount, VoteRepository}
import java.util.UUID

class GetVoteResultsUseCase[F[_]](
  voteRepo: VoteRepository[F]
) extends GetVoteResultsAlg[F] {

  def execute(electionId: UUID): F[List[VoteCount]] =
    voteRepo.countByElection(ElectionId(electionId))
}
