package pt.ipp.estg.election.identity.application

import cats.Monad
import pt.ipp.estg.election.identity.domain._

class LoginVoterUseCase[F[_]: Monad](
  repository:     VoterRepository[F],
  verifier:       PasswordVerifier[F],
  tokenGenerator: TokenGenerator[F]
) extends LoginVoterAlg[F] {

  def execute(civilIdRaw: String, rawPassword: String, ip: String): F[Either[LoginError, (AuthToken, Boolean)]] =
    VoterLoginLogic.login[F](civilIdRaw, rawPassword)(
      findVoter      = id   => repository.findByCivilId(id),
      verifyPassword = (raw, hash) => verifier.verify(raw, hash),
      generateToken  = voter => tokenGenerator.generate(voter)
    )
}
