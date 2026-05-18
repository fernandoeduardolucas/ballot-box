package pt.ipp.estg.election.aop

import cats.FlatMap
import cats.syntax.all.*
import org.typelevel.log4cats.Logger
import pt.ipp.estg.election.identity.application.RegisterVoterAlg
import pt.ipp.estg.election.identity.domain._

final class AuditedRegisterVoterUseCase[F[_]: FlatMap](
    target: RegisterVoterAlg[F],
    logger: Logger[F]
) extends RegisterVoterAlg[F]:

  def execute(civilIdRaw: String, rawPassword: String, nut3Code: String): F[Either[RegistrationError, Voter]] =
    target.execute(civilIdRaw, rawPassword, nut3Code).flatTap {
      case Right(voter) =>
        logger.info(s"[AUDIT] REGISTER_SUCCESS civilId=$civilIdRaw voterId=${voter.id.value}")
      case Left(error) =>
        logger.warn(s"[AUDIT] REGISTER_FAILURE civilId=$civilIdRaw reason=$error")
    }
