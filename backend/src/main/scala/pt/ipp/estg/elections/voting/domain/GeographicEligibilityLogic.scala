package pt.ipp.estg.election.voting.domain

import pt.ipp.estg.election.election.domain.{Election, ElectionScope}
import pt.ipp.estg.election.identity.domain.Voter

object GeographicEligibilityLogic {

  def checkEligibility(voter: Voter, election: Election): Either[VoteError, Unit] =
    election.scope match
      case ElectionScope.National =>
        Right(())

      case ElectionScope.Regional(region) =>
        Either.cond(voter.nut3Region == region, (), VoterNotEligible: VoteError)
}
