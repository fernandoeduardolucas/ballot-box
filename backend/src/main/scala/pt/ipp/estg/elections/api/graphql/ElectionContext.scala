package pt.ipp.estg.election.api.graphql

import cats.effect.IO
import pt.ipp.estg.election.identity.application.RegisterVoterUseCase

case class ElectionContext(
  registerVoterUseCase: RegisterVoterUseCase[IO]
)