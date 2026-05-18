package pt.ipp.estg.election.election.application

import pt.ipp.estg.election.election.domain._

import java.util.UUID

trait AddCandidateAlg[F[_]] {
  def execute(
    electionId: UUID,
    name:       String,
    party:      Option[String],
    photoUrl:   Option[String],
    number:     Int
  ): F[Either[CandidateError, Candidate]]
}
