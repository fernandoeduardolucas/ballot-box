package pt.ipp.estg.elections.repository

import pt.ipp.estg.elections.domain.CandidateId
import pt.ipp.estg.elections.domain.Election
import pt.ipp.estg.elections.domain.ElectionId
import pt.ipp.estg.elections.domain.Voter
import pt.ipp.estg.elections.domain.VoterId
import pt.ipp.estg.elections.domain.Vote

trait ElectionRepository[F[_]]:
  def findElection(id: ElectionId): F[Option[Election]]
  def findVoter(id: VoterId): F[Option[Voter]]
  def saveVoter(voter: Voter): F[Unit]
  def saveVote(vote: Vote): F[Unit]
  def countVotes(electionId: ElectionId): F[Map[CandidateId, Int]]
