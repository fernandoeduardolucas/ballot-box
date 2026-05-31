package pt.ipp.estg.election.election.domain

import java.time.Instant

/** State pattern.
  *
  * Encapsulates election behavior that changes with time. Business rules ask
  * the current state what is allowed instead of duplicating date comparisons.
  */
sealed trait ElectionState:
  def allowsCandidateRegistration: Boolean
  def allowsVoting: Boolean

object ElectionState:
  case object Scheduled extends ElectionState:
    override val allowsCandidateRegistration: Boolean = true
    override val allowsVoting: Boolean                = false

  case object Active extends ElectionState:
    override val allowsCandidateRegistration: Boolean = false
    override val allowsVoting: Boolean                = true

  case object Closed extends ElectionState:
    override val allowsCandidateRegistration: Boolean = false
    override val allowsVoting: Boolean                = false

  def from(election: Election, now: Instant): ElectionState =
    if now.isBefore(election.startDate) then Scheduled
    else if now.isBefore(election.endDate) then Active
    else Closed
