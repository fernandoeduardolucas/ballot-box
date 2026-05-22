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

  def save(vote: Vote): F[Either[VoteError, Unit]] =
    sql"""
      INSERT INTO votes (id, voter_id, election_id, candidate_id, voted_at)
      VALUES (${vote.id.value}, ${vote.voterId.value}, ${vote.electionId.value}, ${vote.candidateId.value}, ${vote.votedAt})
    """.update.run.transact(xa).void.attempt.map {
      case Right(_)                                                      => Right(())
      case Left(e: PSQLException) if e.getSQLState == "23505"            => Left(AlreadyVoted)
      case Left(e)                                                       => throw e
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
      .transact(xa)
      .map(_.map { case (cId, cName, count) =>
        VoteCount(CandidateId(cId), CandidateName(cName), count)
      })
}
