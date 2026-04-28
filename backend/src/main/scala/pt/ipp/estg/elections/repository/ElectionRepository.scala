package pt.ipp.estg.elections.repository

import pt.ipp.estg.elections.domain.CandidateId
import pt.ipp.estg.elections.domain.Election
import pt.ipp.estg.elections.domain.ElectionId
import pt.ipp.estg.elections.domain.Voter
import pt.ipp.estg.elections.domain.VoterId
import pt.ipp.estg.elections.domain.Vote

/** Porta de persistência para entidades eleitorais. */
trait ElectionRepository[F[_]]:
  /** Procura eleição por identificador. */
  def findElection(id: ElectionId): F[Option[Election]]
  /** Procura eleitor por identificador. */
  def findVoter(id: VoterId): F[Option[Voter]]
  /** Persiste dados de eleitor. */
  def saveVoter(voter: Voter): F[Unit]
  /** Persiste voto individual. */
  def saveVote(vote: Vote): F[Unit]
  /** Conta votos por candidato numa eleição. */
  def countVotes(electionId: ElectionId): F[Map[CandidateId, Int]]
