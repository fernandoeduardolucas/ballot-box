package pt.ipp.estg.election.infrastructure

import cats.effect.MonadCancelThrow
import doobie.util.transactor.Transactor
import pt.ipp.estg.election.aop.AuditLogAlg
import pt.ipp.estg.election.election.domain.{CandidateRepository, ElectionRepository}
import pt.ipp.estg.election.election.infrastructure.{DoobieCandidateRepository, DoobieElectionRepository}
import pt.ipp.estg.election.identity.domain.VoterRepository
import pt.ipp.estg.election.identity.infrastructure.{DoobieAuditLogRepository, DoobieVoterRepository}
import pt.ipp.estg.election.voting.domain.VoteRepository
import pt.ipp.estg.election.voting.infrastructure.DoobieVoteRepository

/** Factory pattern.
  *
  * Centralizes repository creation behind domain-facing interfaces, keeping the
  * composition root independent from concrete persistence classes.
  */
trait RepositoryFactory[F[_]]:
  def voterRepository: VoterRepository[F]
  def auditLogRepository: AuditLogAlg[F]
  def electionRepository: ElectionRepository[F]
  def candidateRepository: CandidateRepository[F]
  def voteRepository: VoteRepository[F]

final class DoobieRepositoryFactory[F[_]: MonadCancelThrow](xa: Transactor[F])
    extends RepositoryFactory[F]:

  // Lazy values reuse one repository instance per factory while keeping creation deferred.
  override lazy val voterRepository: VoterRepository[F] =
    new DoobieVoterRepository[F](xa)

  override lazy val auditLogRepository: AuditLogAlg[F] =
    new DoobieAuditLogRepository[F](xa)

  override lazy val electionRepository: ElectionRepository[F] =
    new DoobieElectionRepository[F](xa)

  override lazy val candidateRepository: CandidateRepository[F] =
    new DoobieCandidateRepository[F](xa)

  override lazy val voteRepository: VoteRepository[F] =
    new DoobieVoteRepository[F](xa)
