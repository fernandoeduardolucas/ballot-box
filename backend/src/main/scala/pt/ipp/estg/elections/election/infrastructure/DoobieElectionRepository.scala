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
    val scopeRegion = ElectionScope.regionCode(election.scope)
    sql"""
      INSERT INTO elections (id, title, start_date, end_date, scope_region)
      VALUES (${election.id.value}, ${election.title.value}, ${election.startDate}, ${election.endDate}, $scopeRegion)
    """.update.run.transact(xa).void

  def findById(id: ElectionId): F[Option[Election]] =
    sql"""
      SELECT id, title, start_date, end_date, scope_region
      FROM elections
      WHERE id = ${id.value}
    """.query[(UUID, String, Instant, Instant, Option[String])]
      .option
      .transact(xa)
      .map(_.map { case (id, title, start, end, scopeRegion) =>
        Election(ElectionId(id), ElectionTitle(title), start, end, ElectionScope.fromRegionCode(scopeRegion).getOrElse(ElectionScope.National))
      })

  def findAll(): F[List[Election]] =
    sql"""
      SELECT id, title, start_date, end_date, scope_region
      FROM elections
      ORDER BY start_date DESC
    """.query[(UUID, String, Instant, Instant, Option[String])]
      .to[List]
      .transact(xa)
      .map(_.map { case (id, title, start, end, scopeRegion) =>
        Election(ElectionId(id), ElectionTitle(title), start, end, ElectionScope.fromRegionCode(scopeRegion).getOrElse(ElectionScope.National))
      })

  def findActive(now: Instant): F[List[Election]] =
    sql"""
      SELECT id, title, start_date, end_date, scope_region
      FROM elections
      WHERE start_date <= $now AND end_date >= $now
      ORDER BY start_date ASC
    """.query[(UUID, String, Instant, Instant, Option[String])]
      .to[List]
      .transact(xa)
      .map(_.map { case (id, title, start, end, scopeRegion) =>
        Election(ElectionId(id), ElectionTitle(title), start, end, ElectionScope.fromRegionCode(scopeRegion).getOrElse(ElectionScope.National))
      })
}
