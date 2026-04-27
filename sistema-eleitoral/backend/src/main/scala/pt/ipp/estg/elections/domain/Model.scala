package pt.ipp.estg.elections.domain

import java.time.Instant
import java.util.UUID

final case class ElectionId(value: UUID) extends AnyVal
final case class CandidateId(value: UUID) extends AnyVal
final case class VoterId(value: String) extends AnyVal

final case class Candidate(id: CandidateId, name: String, manifesto: String)
final case class Election(id: ElectionId, title: String, startsAt: Instant, endsAt: Instant, candidates: List[Candidate])
final case class Voter(id: VoterId, fullName: String, eligibleElectionIds: Set[ElectionId], hasVoted: Set[ElectionId])
final case class Vote(electionId: ElectionId, candidateId: CandidateId, voterHash: String, createdAt: Instant)

sealed trait DomainError derives CanEqual
object DomainError:
  final case class NotFound(message: String) extends DomainError
  final case class NotEligible(message: String) extends DomainError
  final case class AlreadyVoted(message: String) extends DomainError
  final case class ElectionClosed(message: String) extends DomainError

sealed trait AuditEvent derives CanEqual:
  def at: Instant
  def actor: String
  def action: String
final case class UserRegistered(actor: String, voterId: VoterId, at: Instant = Instant.now) extends AuditEvent:
  val action = "USER_REGISTERED"
final case class VoteCast(actor: String, electionId: ElectionId, at: Instant = Instant.now) extends AuditEvent:
  val action = "VOTE_CAST"
final case class ResultsPublished(actor: String, electionId: ElectionId, at: Instant = Instant.now) extends AuditEvent:
  val action = "RESULTS_PUBLISHED"
