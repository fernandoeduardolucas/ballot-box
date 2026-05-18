package pt.ipp.estg.election.identity.application

import pt.ipp.estg.election.identity.domain._

trait RegisterVoterAlg[F[_]] {
  def execute(civilIdRaw: String, rawPassword: String, nut3Code: String): F[Either[RegistrationError, Voter]]
}
