package pt.ipp.estg.election.aop

import cats.FlatMap
import cats.syntax.all._
import pt.ipp.estg.election.identity.application.LoginVoterAlg
import pt.ipp.estg.election.identity.domain.{AuthToken, LoginError}

final class AuditedLoginUseCase[F[_]: FlatMap](
  target:   LoginVoterAlg[F],
  auditLog: AuditLogAlg[F]
) extends LoginVoterAlg[F] {

  def execute(civilIdRaw: String, rawPassword: String, ip: String): F[Either[LoginError, AuthToken]] =
    target.execute(civilIdRaw, rawPassword, ip).flatTap {
      case Right(_) =>
        auditLog.record(AuditEvent("LOGIN", Some(civilIdRaw), ip, success = true, reason = None))
      case Left(error) =>
        auditLog.record(AuditEvent("LOGIN", Some(civilIdRaw), ip, success = false, reason = Some(error.toString)))
    }
}
