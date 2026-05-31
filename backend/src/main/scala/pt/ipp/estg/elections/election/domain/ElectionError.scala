package pt.ipp.estg.election.election.domain

sealed trait ElectionError
case object TitleTooShort        extends ElectionError
case object EndDateBeforeStartDate extends ElectionError
case object InvalidElectionScope extends ElectionError
