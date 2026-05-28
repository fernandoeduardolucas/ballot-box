package pt.ipp.estg.election.voting.domain

import pt.ipp.estg.election.election.domain.{CandidateId, CandidateName}

case class VoteCount(
  candidateId:   CandidateId,
  candidateName: CandidateName,
  count:         Long
)
