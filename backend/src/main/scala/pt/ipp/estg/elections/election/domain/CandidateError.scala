package pt.ipp.estg.election.election.domain

sealed trait CandidateError
case object ElectionNotFound       extends CandidateError
case object ElectionAlreadyStarted extends CandidateError
case object CandidateNameTooShort  extends CandidateError
