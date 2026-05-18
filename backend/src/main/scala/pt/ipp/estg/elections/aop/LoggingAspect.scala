package pt.ipp.estg.election.aop

import cats.effect.Sync
import cats.syntax.all.*
import org.typelevel.log4cats.LoggerFactory
import pt.ipp.estg.election.identity.application.RegisterVoterAlg
import pt.ipp.estg.election.identity.domain._

object LoggingAspect:
  def around[F[_]: Sync: LoggerFactory, A](operation: String)(fa: F[A]): F[A] =
    summon[Sync[F]].monotonic.flatMap { start =>
      LoggerFactory[F].getLogger.info(s"[AOP] START $operation") *>
        fa.attempt.flatMap { result =>
          summon[Sync[F]].monotonic.flatMap { end =>
            val elapsed = (end - start).toMillis
            result match
              case Right(value) =>
                LoggerFactory[F].getLogger.info(s"[AOP] END $operation duration=${elapsed}ms") *> value.pure[F]
              case Left(error) =>
                LoggerFactory[F].getLogger.error(error)(s"[AOP] ERROR $operation duration=${elapsed}ms") *> error.raiseError[F, A]
          }
        }
    }

final class LoggedRegisterVoterUseCase[F[_]: Sync: LoggerFactory](target: RegisterVoterAlg[F])
    extends RegisterVoterAlg[F]:

  def execute(civilIdRaw: String, rawPassword: String, nut3Code: String): F[Either[RegistrationError, Voter]] =
    LoggingAspect.around(s"RegisterVoterUseCase.execute civilId=$civilIdRaw"):
      target.execute(civilIdRaw, rawPassword, nut3Code)
