package pt.ipp.estg.elections.domain

import cats.Monad
import cats.data.EitherT
import cats.syntax.all.*
import java.time.Instant

trait ElectionRepository[F[_]]:
  def findElection(id: ElectionId): F[Option[Election]]
  def findVoter(id: VoterId): F[Option[Voter]]
  def saveVoter(voter: Voter): F[Unit]
  def saveVote(vote: Vote): F[Unit]
  def countVotes(electionId: ElectionId): F[Map[CandidateId, Int]]

trait EventPublisher[F[_]]:
  def publish(event: AuditEvent): F[Unit]

final class ElectionService[F[_]: Monad](repo: ElectionRepository[F], events: EventPublisher[F]):
  def registerVoter(voter: Voter): F[Unit] =
    repo.saveVoter(voter) *> events.publish(UserRegistered("system", voter.id))

  def vote(voterId: VoterId, electionId: ElectionId, candidateId: CandidateId): F[Either[DomainError, Unit]] =
    val program = for
      election <- EitherT.fromOptionF(repo.findElection(electionId), DomainError.NotFound("Eleição não encontrada"))
      voter <- EitherT.fromOptionF(repo.findVoter(voterId), DomainError.NotFound("Eleitor não encontrado"))
      now = Instant.now
      _ <- EitherT.cond[F](now.isAfter(election.startsAt) && now.isBefore(election.endsAt), (), DomainError.ElectionClosed("Eleição fora do período de votação"))
      _ <- EitherT.cond[F](voter.eligibleElectionIds.contains(electionId), (), DomainError.NotEligible("Eleitor não elegível"))
      _ <- EitherT.cond[F](!voter.hasVoted.contains(electionId), (), DomainError.AlreadyVoted("Eleitor já votou"))
      _ <- EitherT.liftF(repo.saveVote(Vote(electionId, candidateId, voterId.value.hashCode.toHexString, now)))
      _ <- EitherT.liftF(repo.saveVoter(voter.copy(hasVoted = voter.hasVoted + electionId)))
      _ <- EitherT.liftF(events.publish(VoteCast(voterId.value, electionId)))
    yield ()
    program.value

  def results(electionId: ElectionId): F[Map[CandidateId, Int]] = repo.countVotes(electionId)
