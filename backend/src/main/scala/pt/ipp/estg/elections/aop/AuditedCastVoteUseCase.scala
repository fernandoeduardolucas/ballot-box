package pt.ipp.estg.election.aop

import cats.FlatMap
import cats.syntax.all._
import pt.ipp.estg.election.voting.application.CastVoteAlg
import pt.ipp.estg.election.voting.domain.{AlreadyVoted, Vote, VoteError}
import java.util.UUID

final class AuditedCastVoteUseCase[F[_]: FlatMap](
  target:   CastVoteAlg[F],
  auditLog: AuditLogAlg[F]
) extends CastVoteAlg[F] {

  def execute(voterId: UUID, electionId: UUID, candidateId: UUID, ip: String): F[Either[VoteError, Vote]] =
    target.execute(voterId, electionId, candidateId, ip).flatTap {
      case Right(_) =>
        auditLog.record(AuditEvent("VOTE_CAST", Some(voterId.toString), ip, success = true, reason = Some(electionId.toString)))
      case Left(AlreadyVoted) =>
        auditLog.record(AuditEvent("DOUBLE_VOTE_ATTEMPT", Some(voterId.toString), ip, success = false, reason = Some(electionId.toString)))
      case Left(error) =>
        auditLog.record(AuditEvent("VOTE_CAST", Some(voterId.toString), ip, success = false, reason = Some(error.toString)))
    }
}
