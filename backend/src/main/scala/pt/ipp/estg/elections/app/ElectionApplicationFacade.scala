package pt.ipp.estg.elections.app

import cats.effect.Clock
import cats.effect.kernel.Async
import doobie.Transactor
import org.typelevel.log4cats.LoggerFactory
import pt.ipp.estg.elections.aop.LoggedElectionService
import pt.ipp.estg.elections.api.AuditEventFrameEncoder
import pt.ipp.estg.elections.api.controllers.ElectionController
import pt.ipp.estg.elections.application.services.ElectionUseCasesLive
import pt.ipp.estg.elections.config.AppConfig
import pt.ipp.estg.elections.infra.{EventBus, RepositoryFactory}
import pt.ipp.estg.elections.services.ElectionService

/**
 * Facade: ponto único para montar o grafo principal da aplicação
 * (repositório, serviço, aspetos e controller).
 */
final class ElectionApplicationFacade[F[_]: Async: Clock: LoggerFactory](
  repositoryFactory: RepositoryFactory[F],
  frameEncoder: AuditEventFrameEncoder,
  config: AppConfig
):
  def buildController(transactor: Transactor[F], bus: EventBus[F]): ElectionController[F] =
    val repository = repositoryFactory.create(transactor)
    val baseService = ElectionService[F](repository, bus)
    val loggedService = LoggedElectionService[F](baseService)
    val useCases = ElectionUseCasesLive[F](loggedService, repository)

    ElectionController[F](
      useCases,
      bus,
      frameEncoder,
      config.graphqlPath,
      config.auditWebSocketPath
    )

object ElectionApplicationFacade:
  def apply[F[_]: Async: Clock: LoggerFactory](
    repositoryFactory: RepositoryFactory[F],
    frameEncoder: AuditEventFrameEncoder,
    config: AppConfig
  ): ElectionApplicationFacade[F] =
    new ElectionApplicationFacade[F](repositoryFactory, frameEncoder, config)
