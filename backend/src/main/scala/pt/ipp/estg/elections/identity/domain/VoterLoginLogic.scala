package pt.ipp.estg.election.identity.domain

import cats.Monad
import cats.data.EitherT
import cats.syntax.all._

object VoterLoginLogic {

  def login[F[_]: Monad](
    civilIdStr: String,
    rawPassword: String
  )(
    findVoter:      CivilId => F[Option[Voter]],
    verifyPassword: (String, PasswordHash) => F[Boolean],
    generateToken:  Voter => F[AuthToken]
  ): F[Either[LoginError, (AuthToken, Boolean)]] = {

    val pipeline = for {
      civilId <- EitherT.fromEither[F](
        Either.cond(civilIdStr.nonEmpty, CivilId(civilIdStr), VoterNotFound: LoginError)
      )
      voter  <- EitherT.fromOptionF(findVoter(civilId), VoterNotFound: LoginError)
      valid  <- EitherT.liftF(verifyPassword(rawPassword, voter.password))
      _      <- EitherT.cond[F](valid, (), InvalidPassword: LoginError)
      token  <- EitherT.liftF(generateToken(voter))
    } yield (token, voter.isAdmin)

    pipeline.value
  }
}
