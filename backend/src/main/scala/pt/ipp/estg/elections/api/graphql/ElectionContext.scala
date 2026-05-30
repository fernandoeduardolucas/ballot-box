package pt.ipp.estg.election.api.graphql

import cats.effect.IO
import cats.effect.std.Dispatcher
import pt.ipp.estg.election.application.ElectionApplicationFacade
import pt.ipp.estg.election.identity.domain.AuthenticatedVoter

case class ElectionContext(
  application:        ElectionApplicationFacade[IO],
  authenticatedVoter: Option[AuthenticatedVoter],
  dispatcher:         Dispatcher[IO],
  requestIp:          String
)
