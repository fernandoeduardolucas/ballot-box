package pt.ipp.estg.election.identity.infrastructure

import cats.effect.Sync
import org.mindrot.jbcrypt.BCrypt
import pt.ipp.estg.election.identity.application.PasswordHasher
import pt.ipp.estg.election.identity.domain.PasswordHash

class BcryptPasswordHasher[F[_]: Sync] extends PasswordHasher[F] {
  
  def hash(rawPassword: String): F[PasswordHash] = {

    Sync[F].delay {
      val hashed = BCrypt.hashpw(rawPassword, BCrypt.gensalt(12))
      PasswordHash(hashed)
    }
  }
}