package pt.ipp.estg.election.election.infrastructure

import cats.effect.MonadCancelThrow
import cats.syntax.functor._
import doobie._
import doobie.implicits._
import doobie.postgres.implicits._
import pt.ipp.estg.election.election.domain._
import java.time.Instant
import java.util.UUID

class DoobieElectionRepository[F[_]: MonadCancelThrow](xa: Transactor[F]) extends ElectionRepository[F] {

  def save(election: Election): F[Unit] =
    sql"""
      INSERT INTO elections (id, title, start_date, end_date)
      VALUES (${election.id.value}, ${election.title.value}, ${election.startDate}, ${election.endDate})
    """.update.run.transact(xa).void

  def findById(id: ElectionId): F[Option[Election]] =
    sql"""
      SELECT id, title, start_date, end_date
      FROM elections
      WHERE id = ${id.value}
    """.query[(UUID, String, Instant, Instant)]
      .option
      .transact(xa)
      .map(_.map { case (id, title, start, end) =>
        Election(ElectionId(id), ElectionTitle(title), start, end)
      })
}
