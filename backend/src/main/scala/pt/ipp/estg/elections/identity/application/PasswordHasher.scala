package pt.ipp.estg.election.identity.application

import pt.ipp.estg.election.identity.domain.PasswordHash

trait PasswordHasher[F[_]] {
  def hash(rawPassword: String): F[PasswordHash]
}