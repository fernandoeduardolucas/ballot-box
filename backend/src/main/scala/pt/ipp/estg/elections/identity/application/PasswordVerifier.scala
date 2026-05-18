package pt.ipp.estg.election.identity.application

import pt.ipp.estg.election.identity.domain.PasswordHash

trait PasswordVerifier[F[_]] {
  def verify(rawPassword: String, hash: PasswordHash): F[Boolean]
}
