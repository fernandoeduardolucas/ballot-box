package pt.ipp.estg.election.identity.application

import pt.ipp.estg.election.identity.domain.{AuthToken, Voter}

trait TokenGenerator[F[_]] {
  def generate(voter: Voter): F[AuthToken]
}
