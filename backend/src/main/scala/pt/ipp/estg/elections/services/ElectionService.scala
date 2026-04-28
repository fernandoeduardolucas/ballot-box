package pt.ipp.estg.elections.services

import cats.Monad
import cats.data.EitherT
import cats.syntax.all.*
import java.time.Instant
import pt.ipp.estg.elections.domain.*
import pt.ipp.estg.elections.repository.ElectionRepository

/** Contrato de casos de uso eleitorais. */
trait ElectionServiceAlg[F[_]]:
  def registerVoter(voter: Voter): F[Unit]
  def vote(voterId: VoterId, electionId: ElectionId, candidateId: CandidateId): F[Either[DomainError, Unit]]
  def results(electionId: ElectionId): F[Map[CandidateId, Int]]

/** Implementação funcional da lógica de negócio eleitoral. */
final class ElectionService[F[_]: Monad](repo: ElectionRepository[F], events: EventPublisher[F]) extends ElectionServiceAlg[F]:
  /** Regista eleitor e emite evento de auditoria. */
  def registerVoter(voter: Voter): F[Unit] =
    repo.saveVoter(voter) *> events.publish(UserRegistered("system", voter.id))

  /** Valida regras de votação e executa persistência em caso de sucesso. */
  def vote(voterId: VoterId, electionId: ElectionId, candidateId: CandidateId): F[Either[DomainError, Unit]] =
    val validatedVote = for
      election <- EitherT.fromOptionF(repo.findElection(electionId), DomainError.NotFound("Eleição não encontrada"))
      voter <- EitherT.fromOptionF(repo.findVoter(voterId), DomainError.NotFound("Eleitor não encontrado"))
      now = Instant.now
      electionOpenValidation <- EitherT.cond[F](
        now.isAfter(election.startsAt) && now.isBefore(election.endsAt),
        (),
        DomainError.ElectionClosed("Eleição fora do período de votação")
      )
      voterEligibilityValidation <- EitherT.cond[F](
        voter.eligibleElectionIds.contains(electionId),
        (),
        DomainError.NotEligible("Eleitor não elegível")
      )
      voteAvailabilityValidation <- EitherT.cond[F](
        !voter.hasVoted.contains(electionId),
        (),
        DomainError.AlreadyVoted("Eleitor já votou")
      )
    yield (voter, now, electionOpenValidation, voterEligibilityValidation, voteAvailabilityValidation)

    validatedVote.semiflatMap { (voter, now, electionOpenValidation, voterEligibilityValidation, voteAvailabilityValidation) =>
      // Lista explícita para deixar claro o encadeamento das validações aprovadas.
      val validations = List(electionOpenValidation, voterEligibilityValidation, voteAvailabilityValidation)
      val vote = Vote(electionId, candidateId, voterId.value.hashCode.toHexString, now)
      val updatedVoter = voter.copy(hasVoted = voter.hasVoted + electionId)
      val auditEvent = VoteCast(voterId.value, electionId)

      validations.foldLeft(repo.saveVote(vote)) { (currentStep, validationStep) =>
        currentStep *> validationStep.pure[F]
      } *> repo.saveVoter(updatedVoter) *> events.publish(auditEvent)
    }.value

  /** Retorna resultados agregados por candidato. */
  def results(electionId: ElectionId): F[Map[CandidateId, Int]] =
    repo.countVotes(electionId)
