package pt.ipp.estg.election.identity.infrastructure

import cats.effect.Sync
import org.mindrot.jbcrypt.BCrypt
import pt.ipp.estg.election.identity.application.PasswordVerifier
import pt.ipp.estg.election.identity.domain.PasswordHash

class BcryptPasswordVerifier[F[_]: Sync] extends PasswordVerifier[F] {

  def verify(rawPassword: String, hash: PasswordHash): F[Boolean] =
    Sync[F].delay(BCrypt.checkpw(rawPassword, hash.value))
}
