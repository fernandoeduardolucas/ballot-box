package pt.ipp.estg.elections.application.ports.in

import pt.ipp.estg.elections.domain.*

/** Input Port (Clean Architecture): casos de uso expostos à camada de interface. */
trait ElectionUseCases[F[_]]:
  def findElection(electionId: ElectionId): F[Option[Election]]
  def registerVoter(voter: Voter): F[Unit]
  def vote(voterId: VoterId, electionId: ElectionId, candidateId: CandidateId): F[Either[DomainError, Unit]]
  def results(electionId: ElectionId): F[Map[CandidateId, Int]]
