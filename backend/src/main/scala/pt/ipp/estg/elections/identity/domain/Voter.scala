package pt.ipp.estg.election.identity.domain

import java.util.UUID

case class VoterId(value: UUID) extends AnyVal
case class CivilId(value: String) extends AnyVal
case class PasswordHash(value: String) extends AnyVal

case class Voter(id: VoterId, civilId: CivilId, password: PasswordHash, nut3Region: Nut3Region, isAdmin: Boolean = false)

object Voter {
  def validateFormat(
    civilId: String,
    rawPassword: String,
    nut3Code: String
  ): Either[RegistrationError, (CivilId, String, Nut3Region)] = {
    for {
      _      <- Either.cond(civilId.length >= 8, (), InvalidCivilIdFormat)
      _      <- Either.cond(rawPassword.length >= 8, (), WeakPassword)
      region <- Nut3Region.fromCode(nut3Code).toRight(InvalidNut3Region: RegistrationError)
    } yield (CivilId(civilId), rawPassword, region)
  }
}