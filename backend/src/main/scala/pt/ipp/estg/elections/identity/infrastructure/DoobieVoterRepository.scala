package pt.ipp.estg.election.identity.infrastructure

import cats.effect.MonadCancelThrow
import cats.syntax.functor._
import doobie._
import doobie.implicits._
import pt.ipp.estg.election.identity.domain.{CivilId, Voter, VoterRepository}
import java.util.UUID

class DoobieVoterRepository[F[_]: MonadCancelThrow](xa: Transactor[F]) extends VoterRepository[F] {

  import doobie.postgres.implicits._

  def checkExists(civilId: CivilId): F[Boolean] = {
    sql"SELECT EXISTS(SELECT 1 FROM voters WHERE civil_id = ${civilId.value})"
      .query[Boolean]
      .unique
      .transact(xa) 
  }

  def save(voter: Voter): F[Unit] = {
    sql"""
      INSERT INTO voters (id, civil_id, password_hash)
      VALUES (${voter.id.value}, ${voter.civilId.value}, ${voter.password.value})
    """
      .update
      .run
      .transact(xa)
      .void 
  }
}