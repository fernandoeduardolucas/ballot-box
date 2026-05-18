package pt.ipp.estg.election.api.graphql

import cats.effect.IO
import cats.effect.std.Dispatcher
import pt.ipp.estg.election.election.application.CreateElectionAlg
import pt.ipp.estg.election.identity.application.{LoginVoterAlg, RegisterVoterAlg}

case class ElectionContext(
  registerVoterUseCase:  RegisterVoterAlg[IO],
  loginVoterUseCase:     LoginVoterAlg[IO],
  createElectionUseCase: CreateElectionAlg[IO],
  dispatcher:            Dispatcher[IO],
  requestIp:             String
)
