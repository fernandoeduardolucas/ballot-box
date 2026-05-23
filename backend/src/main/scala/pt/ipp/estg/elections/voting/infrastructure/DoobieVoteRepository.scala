package pt.ipp.estg.election.voting.infrastructure

import cats.effect.MonadCancelThrow
import cats.syntax.applicativeError._
import cats.syntax.functor._
import doobie._
import doobie.implicits._
import doobie.postgres.implicits._
import org.postgresql.util.PSQLException
import pt.ipp.estg.election.election.domain.{CandidateId, CandidateName, ElectionId}
import pt.ipp.estg.election.voting.domain.{AlreadyVoted, Vote, VoteCount, VoteError, VoteRepository}

import java.util.UUID

class DoobieVoteRepository[F[_]: MonadCancelThrow](xa: Transactor[F]) extends VoteRepository[F] {

  def save(vote: Vote): ConnectionIO[Either[VoteError, Unit]] = {
    import doobie.postgres.sqlstate.class23.UNIQUE_VIOLATION
    import cats.Applicative

    sql"""
      INSERT INTO election_participations (voter_id, election_id)
      VALUES (${vote.voterId.value}, ${vote.electionId.value})
    """.update.run.void
      .map[Either[VoteError, Unit]](_ => Right(()))
      .exceptSomeSqlState {
        case UNIQUE_VIOLATION => Applicative[ConnectionIO].pure(Left(AlreadyVoted))
      }
  }

  def countByElection(electionId: ElectionId): F[List[VoteCount]] =
    sql"""
      SELECT c.id, c.name, COUNT(v.id)
      FROM candidates c
      LEFT JOIN votes v ON v.candidate_id = c.id
      WHERE c.election_id = ${electionId.value}
      GROUP BY c.id, c.name, c.number
      ORDER BY c.number
    """.query[(UUID, String, Long)]
      .to[List]
      .to[List]
      .transact(xa)
      .map(_.map { case (cId, cName, count) =>
        VoteCount(CandidateId(cId), CandidateName(cName), count)
      })
  
  def incrementCandidateTotal(candidateId: CandidateId): ConnectionIO[Unit] =
    sql"""
      INSERT INTO votes (id, election_id, candidate_id)
      SELECT gen_random_uuid(), election_id, id 
      FROM candidates WHERE id = ${candidateId.value}
    """.update.run.void
}
