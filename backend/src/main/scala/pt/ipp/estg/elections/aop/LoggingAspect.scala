package pt.ipp.estg.election.aop

import cats.effect.Sync
import cats.syntax.all.*
import org.typelevel.log4cats.LoggerFactory

/**
 * AOP-style logging helpers.
 *
 * Cross-cutting logging remains isolated here instead of being repeated inside
 * application services. The `around` method wraps an effect, logs start/end,
 * measures duration, and logs failures.
 */
object LoggingAspect:
  /** Wraps a computation with start/end logs and latency measurement. */
  def around[F[_]: Sync: LoggerFactory, A](operation: String)(fa: F[A]): F[A] =
    Sync[F].monotonic.flatMap { start =>
      LoggerFactory[F].getLogger.info(s"[AOP] START $operation") *>
        fa.attempt.flatMap { result =>
          Sync[F].monotonic.flatMap { end =>
            val elapsed = (end - start).toMillis
            result match
              case Right(value) =>
                LoggerFactory[F].getLogger.info(s"[AOP] END $operation duration=${elapsed}ms") *> value.pure[F]
              case Left(error) =>
                LoggerFactory[F].getLogger.error(error)(s"[AOP] ERROR $operation duration=${elapsed}ms") *> error.raiseError[F, A]
          }
        }
    }
