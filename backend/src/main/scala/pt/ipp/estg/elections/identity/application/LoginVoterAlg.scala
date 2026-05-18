package pt.ipp.estg.election.identity.application

import pt.ipp.estg.election.identity.domain.{AuthToken, LoginError}

trait LoginVoterAlg[F[_]] {
  def execute(civilIdRaw: String, rawPassword: String, ip: String): F[Either[LoginError, (AuthToken, Boolean)]]
}
