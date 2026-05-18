package pt.ipp.estg.election.election.infrastructure

import cats.effect.MonadCancelThrow
import cats.syntax.functor._
import doobie._
import doobie.implicits._
import doobie.postgres.implicits._
import pt.ipp.estg.election.election.domain._

import java.util.UUID

class DoobieCandidateRepository[F[_]: MonadCancelThrow](xa: Transactor[F])
    extends CandidateRepository[F] {

  def save(candidate: Candidate): F[Unit] =
    sql"""
      INSERT INTO candidates (id, election_id, name, party, photo_url, number)
      VALUES (
        ${candidate.id.value},
        ${candidate.electionId.value},
        ${candidate.name.value},
        ${candidate.party},
        ${candidate.photoUrl},
        ${candidate.number}
      )
    """.update.run.transact(xa).void

  def findByElection(electionId: ElectionId): F[List[Candidate]] =
    sql"""
      SELECT id, election_id, name, party, photo_url, number
      FROM candidates
      WHERE election_id = ${electionId.value}
      ORDER BY number ASC
    """
      .query[(UUID, UUID, String, Option[String], Option[String], Int)]
      .to[List]
      .transact(xa)
      .map(_.map { case (id, eId, name, party, photo, number) =>
        Candidate(CandidateId(id), ElectionId(eId), CandidateName(name), party, photo, number)
      })
}
