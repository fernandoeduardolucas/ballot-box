package pt.ipp.estg.election.identity.domain

import cats.Monad
import cats.data.EitherT
import cats.syntax.all._
import java.util.UUID

object VoterRegistrationLogic {


  def registerVoter[F[_]: Monad](
    civilIdStr: String,
    rawPassword: String
  )(
    checkCivilIdExists: CivilId => F[Boolean],
    hashPassword: String => F[PasswordHash]
  ): F[Either[RegistrationError, Voter]] = {

    val pipeline = for {
      validInputs <- EitherT.fromEither[F](Voter.validateFormat(civilIdStr, rawPassword))
      (civilId, validPassword) = validInputs

      exists <- EitherT.liftF(checkCivilIdExists(civilId))
      _ <- EitherT.cond[F](!exists, (), CivilIdAlreadyExists: RegistrationError)

      hashed <- EitherT.liftF(hashPassword(validPassword))
    } yield Voter(VoterId(UUID.randomUUID()), civilId, hashed)

    pipeline.value
  }
}