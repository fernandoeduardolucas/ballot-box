package pt.ipp.estg.election.identity.domain

case class AuthenticatedVoter(id: VoterId, civilId: CivilId, nut3Region: Nut3Region, isAdmin: Boolean)
