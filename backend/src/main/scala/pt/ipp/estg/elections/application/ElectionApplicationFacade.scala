package pt.ipp.estg.election.application

import pt.ipp.estg.election.election.application.{
  AddCandidateAlg,
  CreateElectionAlg,
  ListActiveElectionsAlg,
  ListAllElectionsAlg,
  ListElectionCandidatesAlg
}
import pt.ipp.estg.election.identity.application.{LoginVoterAlg, RegisterVoterAlg}
import pt.ipp.estg.election.voting.application.{CastVoteAlg, GetVoteResultsAlg}

/** Facade pattern.
  *
  * Exposes the application layer through one cohesive entry point, so callers
  * such as GraphQL do not need to know how many use cases exist or how they are
  * wired together.
  */
final case class ElectionApplicationFacade[F[_]](
  registerVoter:          RegisterVoterAlg[F],
  loginVoter:             LoginVoterAlg[F],
  createElection:         CreateElectionAlg[F],
  addCandidate:           AddCandidateAlg[F],
  listActiveElections:    ListActiveElectionsAlg[F],
  listAllElections:       ListAllElectionsAlg[F],
  listElectionCandidates: ListElectionCandidatesAlg[F],
  castVote:               CastVoteAlg[F],
  getVoteResults:         GetVoteResultsAlg[F]
)
