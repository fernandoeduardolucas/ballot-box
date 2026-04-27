package pt.ipp.estg.elections.infra

import cats.effect.kernel.Async
import cats.syntax.all.*
import doobie.*
import doobie.implicits.*
import doobie.postgres.implicits.*
import java.time.Instant
import java.util.UUID
import pt.ipp.estg.elections.domain.*
import pt.ipp.estg.elections.repository.ElectionRepository

final class PostgresRepository[F[_]: Async](xa: Transactor[F]) extends ElectionRepository[F]:
  def findElection(id: ElectionId): F[Option[Election]] =
    val electionQuery = sql"""
      select id, title, starts_at, ends_at
      from elections
      where id = ${id.value}
    """.query[(UUID, String, Instant, Instant)].option

    val candidatesQuery = sql"""
      select id, name, manifesto
      from candidates
      where election_id = ${id.value}
      order by name
    """.query[(UUID, String, String)].to[List]

    (electionQuery, candidatesQuery).mapN { (electionRow, candidateRows) =>
      electionRow.map { (electionId, title, startsAt, endsAt) =>
        val candidates = candidateRows.map { (candidateId, name, manifesto) =>
          Candidate(CandidateId(candidateId), name, manifesto)
        }
        Election(ElectionId(electionId), title, startsAt, endsAt, candidates)
      }
    }.transact(xa)

  def findVoter(id: VoterId): F[Option[Voter]] =
    val voterQuery = sql"""
      select id, full_name
      from voters
      where id = ${id.value}
    """.query[(String, String)].option

    val eligibleElectionsQuery = sql"""
      select id
      from elections
    """.query[UUID].to[List]

    val votedElectionsQuery = sql"""
      select election_id
      from votes
      where voter_hash = ${id.value.hashCode.toHexString}
    """.query[UUID].to[List]

    (voterQuery, eligibleElectionsQuery, votedElectionsQuery).mapN {
      (voterRow, eligibleElectionRows, votedElectionRows) =>
        voterRow.map { (voterId, fullName) =>
          val eligibleElectionIds = eligibleElectionRows.map(uuid => ElectionId(uuid)).toSet
          val hasVoted = votedElectionRows.map(uuid => ElectionId(uuid)).toSet
          Voter(VoterId(voterId), fullName, eligibleElectionIds, hasVoted)
        }
    }.transact(xa)

  def saveVoter(voter: Voter): F[Unit] =
    sql"""
      insert into voters (id, full_name)
      values (${voter.id.value}, ${voter.fullName})
      on conflict (id) do update
      set full_name = excluded.full_name
    """.update.run.transact(xa).void

  def saveVote(vote: Vote): F[Unit] =
    sql"""
      insert into votes (election_id, candidate_id, voter_hash, created_at)
      values (${vote.electionId.value}, ${vote.candidateId.value}, ${vote.voterHash}, ${vote.createdAt})
    """.update.run.transact(xa).void

  def countVotes(electionId: ElectionId): F[Map[CandidateId, Int]] =
    sql"""
      select candidate_id, count(*)::int
      from votes
      where election_id = ${electionId.value}
      group by candidate_id
    """.query[(UUID, Int)].to[List].map { rows =>
      rows.map { (candidateId, totalVotes) =>
        CandidateId(candidateId) -> totalVotes
      }.toMap
    }.transact(xa)

