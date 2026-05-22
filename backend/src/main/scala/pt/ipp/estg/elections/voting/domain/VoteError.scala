package pt.ipp.estg.election.voting.domain

sealed trait VoteError
case object ElectionNotActive      extends VoteError
case object CandidateNotInElection extends VoteError
case object AlreadyVoted           extends VoteError
