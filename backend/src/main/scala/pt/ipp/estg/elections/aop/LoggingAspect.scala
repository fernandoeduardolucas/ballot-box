package pt.ipp.estg.elections.aop

import cats.effect.{Clock, Sync}
import cats.syntax.all.*
import org.typelevel.log4cats.LoggerFactory
import pt.ipp.estg.elections.domain.*
import scala.concurrent.duration.*

/**
 * AOP-style logging aspect.
 *
 * A lógica transversal de logging fica isolada aqui, em vez de ser repetida
 * dentro dos serviços de domínio. O método `around` envolve uma operação,
 * regista início/fim, mede duração e captura erros.
 */
object LoggingAspect:
  def around[F[_]: Sync: Clock: LoggerFactory, A](operation: String)(fa: F[A]): F[A] =
    for
      start <- Clock[F].monotonic
      _ <- LoggerFactory[F].getLogger.info(s"[AOP] START $operation")
      result <- fa.attempt
      end <- Clock[F].monotonic
      elapsed = (end - start).toMillis
      value <- result match
        case Right(value) =>
          LoggerFactory[F].getLogger.info(s"[AOP] END $operation duration=${elapsed}ms") *> value.pure[F]
        case Left(error) =>
          LoggerFactory[F].getLogger.error(error)(s"[AOP] ERROR $operation duration=${elapsed}ms") *> error.raiseError[F, A]
    yield value

/**
 * Decorator/AOP proxy para o serviço eleitoral.
 *
 * O domínio continua limpo e funcional; os logs são adicionados por composição.
 */
final class LoggedElectionService[F[_]: Sync: Clock: LoggerFactory](target: ElectionServiceAlg[F]) extends ElectionServiceAlg[F]:
  def registerVoter(voter: Voter): F[Unit] =
    LoggingAspect.around(s"ElectionService.registerVoter voterId=${voter.id.value}"):
      target.registerVoter(voter)

  def vote(voterId: VoterId, electionId: ElectionId, candidateId: CandidateId): F[Either[DomainError, Unit]] =
    LoggingAspect.around(s"ElectionService.vote voterId=${voterId.value} electionId=${electionId.value} candidateId=${candidateId.value}"):
      target.vote(voterId, electionId, candidateId)

  def results(electionId: ElectionId): F[Map[CandidateId, Int]] =
    LoggingAspect.around(s"ElectionService.results electionId=${electionId.value}"):
      target.results(electionId)
