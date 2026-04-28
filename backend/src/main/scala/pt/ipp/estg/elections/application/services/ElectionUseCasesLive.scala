package pt.ipp.estg.elections.application.services

import pt.ipp.estg.elections.application.ports.in.ElectionUseCases
import pt.ipp.estg.elections.domain.*
import pt.ipp.estg.elections.repository.ElectionRepository
import pt.ipp.estg.elections.services.ElectionServiceAlg

/** Implementação dos casos de uso (Application Layer). */
final class ElectionUseCasesLive[F[_]](
  electionService: ElectionServiceAlg[F],
  electionRepository: ElectionRepository[F]
) extends ElectionUseCases[F]:
  override def findElection(electionId: ElectionId): F[Option[Election]] =
    electionRepository.findElection(electionId)

  override def registerVoter(voter: Voter): F[Unit] =
    electionService.registerVoter(voter)

  override def vote(voterId: VoterId, electionId: ElectionId, candidateId: CandidateId): F[Either[DomainError, Unit]] =
    electionService.vote(voterId, electionId, candidateId)

  override def results(electionId: ElectionId): F[Map[CandidateId, Int]] =
    electionService.results(electionId)

object ElectionUseCasesLive:
  def apply[F[_]](
    electionService: ElectionServiceAlg[F],
    electionRepository: ElectionRepository[F]
  ): ElectionUseCasesLive[F] =
    new ElectionUseCasesLive[F](electionService, electionRepository)
