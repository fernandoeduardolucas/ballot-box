package pt.ipp.estg.elections.infra

import cats.effect.Ref
import cats.effect.kernel.Sync
import cats.syntax.all.*
import pt.ipp.estg.elections.domain.*
import pt.ipp.estg.elections.repository.ElectionRepository
import java.time.Instant
import java.util.UUID

final class InMemoryRepository[F[_]: Sync](state: Ref[F, InMemoryRepository.State]) extends ElectionRepository[F]:
  def findElection(id: ElectionId): F[Option[Election]] =
    state.get.map { currentState =>
      currentState.elections.get(id)
    }

  def findVoter(id: VoterId): F[Option[Voter]] =
    state.get.map { currentState =>
      currentState.voters.get(id)
    }

  def saveVoter(voter: Voter): F[Unit] =
    state.update { currentState =>
      val updatedVoters = currentState.voters.updated(voter.id, voter)
      currentState.copy(voters = updatedVoters)
    }

  def saveVote(vote: Vote): F[Unit] =
    state.update { currentState =>
      val updatedVotes = vote :: currentState.votes
      currentState.copy(votes = updatedVotes)
    }

  def countVotes(electionId: ElectionId): F[Map[CandidateId, Int]] =
    state.get.map { currentState =>
      val votesForElection = currentState.votes.filter { vote =>
        vote.electionId == electionId
      }

      votesForElection.groupMapReduce(vote => vote.candidateId)(vote => 1) { (leftCount, rightCount) =>
        leftCount + rightCount
      }
    }

object InMemoryRepository:
  final case class State(elections: Map[ElectionId, Election], voters: Map[VoterId, Voter], votes: List[Vote])

  def create[F[_]: Sync]: F[InMemoryRepository[F]] =
    val eId = ElectionId(UUID.fromString("11111111-1111-1111-1111-111111111111"))
    val c1 = Candidate(CandidateId(UUID.fromString("22222222-2222-2222-2222-222222222222")), "Lista A", "Transparência e acessibilidade")
    val c2 = Candidate(CandidateId(UUID.fromString("33333333-3333-3333-3333-333333333333")), "Lista B", "Segurança e participação")
    val election = Election(eId, "Eleição Académica 2026", Instant.parse("2026-01-01T00:00:00Z"), Instant.parse("2026-12-31T23:59:59Z"), List(c1, c2))
    Ref
      .of[F, State](State(Map(eId -> election), Map.empty, Nil))
      .map(initialState => new InMemoryRepository[F](initialState))
