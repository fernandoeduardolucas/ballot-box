package pt.ipp.estg.election.election.application

import pt.ipp.estg.election.election.domain._
import java.time.Instant

trait CreateElectionAlg[F[_]] {
  def execute(title: String, startDate: Instant, endDate: Instant): F[Either[ElectionError, Election]]
}
