package pt.ipp.estg.election.identity.domain

sealed trait LoginError
case object VoterNotFound   extends LoginError
case object InvalidPassword extends LoginError
