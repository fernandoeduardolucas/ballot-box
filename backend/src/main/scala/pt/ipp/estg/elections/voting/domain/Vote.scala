package pt.ipp.estg.election.voting.domain

import java.time.Instant
import java.util.UUID
import pt.ipp.estg.election.election.domain.{ElectionId, CandidateId}
import pt.ipp.estg.election.identity.domain.VoterId

case class VoteId(value: UUID) extends AnyVal

case class Vote(
  id:          VoteId,
  voterId:     VoterId,
  electionId:  ElectionId,
  candidateId: CandidateId,
  votedAt:     Instant
)
