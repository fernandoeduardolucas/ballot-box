package pt.ipp.estg.election.identity.domain

import java.util.UUID

case class VoterId(value: UUID) extends AnyVal
case class CivilId(value: String) extends AnyVal
case class PasswordHash(value: String) extends AnyVal

case class Voter(id: VoterId, civilId: CivilId, password: PasswordHash)

object Voter {
  def validateFormat(civilId: String, rawPassword: String): Either[RegistrationError, (CivilId, String)] = {
    for {
      _ <- Either.cond(civilId.length >= 8, (), InvalidCivilIdFormat)
      _ <- Either.cond(rawPassword.length >= 8, (), WeakPassword)
    } yield (CivilId(civilId), rawPassword)
  }
}