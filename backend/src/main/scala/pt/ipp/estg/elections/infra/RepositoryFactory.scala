package pt.ipp.estg.elections.infra

import cats.effect.kernel.Async
import doobie.Transactor
import pt.ipp.estg.elections.repository.ElectionRepository

/** Factory Method: cria repositórios a partir de dependências de infraestrutura. */
trait RepositoryFactory[F[_]]:
  def create(transactor: Transactor[F]): ElectionRepository[F]

/** Factory concreta para repositório PostgreSQL. */
final class PostgresRepositoryFactory[F[_]: Async] extends RepositoryFactory[F]:
  override def create(transactor: Transactor[F]): ElectionRepository[F] =
    PostgresRepository[F](transactor)

object PostgresRepositoryFactory:
  def apply[F[_]: Async](): PostgresRepositoryFactory[F] = new PostgresRepositoryFactory[F]()
