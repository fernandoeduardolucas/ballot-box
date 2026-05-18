package pt.ipp.estg.election.election.domain

import java.util.UUID

case class CandidateId(value: UUID)     extends AnyVal
case class CandidateName(value: String) extends AnyVal

case class Candidate(
  id:        CandidateId,
  electionId: ElectionId,
  name:      CandidateName,
  party:     Option[String],
  photoUrl:  Option[String],
  number:    Int
)
