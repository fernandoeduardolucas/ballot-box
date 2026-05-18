package pt.ipp.estg.election.identity.application

import pt.ipp.estg.election.identity.domain.AuthenticatedVoter

trait TokenVerifier[F[_]] {
  def verify(rawToken: String): F[Option[AuthenticatedVoter]]
}
