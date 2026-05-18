package pt.ipp.estg.election.api.graphql

import cats.effect.IO
import cats.effect.std.Dispatcher
import pt.ipp.estg.election.election.application.{AddCandidateAlg, CreateElectionAlg, ListActiveElectionsAlg, ListAllElectionsAlg, ListElectionCandidatesAlg}
import pt.ipp.estg.election.identity.application.{LoginVoterAlg, RegisterVoterAlg}
import pt.ipp.estg.election.identity.domain.AuthenticatedVoter

case class ElectionContext(
  registerVoterUseCase:          RegisterVoterAlg[IO],
  loginVoterUseCase:             LoginVoterAlg[IO],
  createElectionUseCase:         CreateElectionAlg[IO],
  addCandidateUseCase:           AddCandidateAlg[IO],
  listActiveElectionsUseCase:    ListActiveElectionsAlg[IO],
  listAllElectionsUseCase:       ListAllElectionsAlg[IO],
  listElectionCandidatesUseCase: ListElectionCandidatesAlg[IO],
  authenticatedVoter:            Option[AuthenticatedVoter],
  dispatcher:                    Dispatcher[IO],
  requestIp:                     String
)
