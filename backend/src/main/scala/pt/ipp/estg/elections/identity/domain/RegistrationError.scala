package pt.ipp.estg.election.identity.domain

sealed trait RegistrationError
case object CivilIdAlreadyExists extends RegistrationError
case object InvalidCivilIdFormat extends RegistrationError
case object WeakPassword extends RegistrationError