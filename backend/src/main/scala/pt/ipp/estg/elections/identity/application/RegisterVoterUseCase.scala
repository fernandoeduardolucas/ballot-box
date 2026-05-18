package pt.ipp.estg.election.identity.application

import cats.Monad
import cats.data.EitherT
import pt.ipp.estg.election.identity.domain._

class RegisterVoterUseCase[F[_]: Monad](
  repository: VoterRepository[F],
  hasher: PasswordHasher[F]
) extends RegisterVoterAlg[F] {

  def execute(civilIdRaw: String, rawPassword: String, nut3Code: String): F[Either[RegistrationError, Voter]] = {

    val domainResult: F[Either[RegistrationError, Voter]] = VoterRegistrationLogic.registerVoter[F](
      civilIdRaw,
      rawPassword,
      nut3Code
    )(
      checkCivilIdExists = id => repository.checkExists(id),
      hashPassword = pass => hasher.hash(pass)
    )

    val pipeline = for {
      voter <- EitherT(domainResult)
      _     <- EitherT.liftF(repository.save(voter))
    } yield voter

    pipeline.value
  }
}