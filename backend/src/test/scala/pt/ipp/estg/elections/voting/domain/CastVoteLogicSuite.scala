package pt.ipp.estg.election

import java.time.Instant
import java.util.UUID
import pt.ipp.estg.election.election.domain._
import pt.ipp.estg.election.identity.domain._
import pt.ipp.estg.election.voting.domain._

class CastVoteLogicSuite extends munit.FunSuite:

  val now: Instant = Instant.parse("2026-05-21T12:00:00Z")

  val electionId: ElectionId = ElectionId(UUID.randomUUID())
  val otherId:    ElectionId = ElectionId(UUID.randomUUID())

  val activeElection: Election = Election(
    id        = electionId,
    title     = ElectionTitle("Election Test"),
    startDate = now.minusSeconds(3600),
    endDate   = now.plusSeconds(3600)
  )

  val candidateId: CandidateId = CandidateId(UUID.randomUUID())

  val validCandidate: Candidate = Candidate(
    id         = candidateId,
    electionId = electionId,
    name       = CandidateName("Candidate A"),
    party      = None,
    photoUrl   = None,
    number     = 1
  )

  val wrongElectionCandidate: Candidate = validCandidate.copy(electionId = otherId)

  val voter: Voter = Voter(
    id         = VoterId(UUID.randomUUID()),
    civilId    = CivilId("12345678"),
    password   = PasswordHash("hashed-password"),
    nut3Region = Nut3Region.AreaMetropolitanaPorto
  )

  test("rejects vote before election starts"):
    val notStarted = activeElection.copy(startDate = now.plusSeconds(60))
    assertEquals(CastVoteLogic.validate(notStarted, validCandidate, now), Left(ElectionNotActive))

  test("rejects vote after election ends"):
    val ended = activeElection.copy(endDate = now.minusSeconds(60))
    assertEquals(CastVoteLogic.validate(ended, validCandidate, now), Left(ElectionNotActive))

  test("accepts vote exactly at start"):
    val atStart = activeElection.copy(startDate = now)
    assertEquals(CastVoteLogic.validate(atStart, validCandidate, now), Right(()))

  test("classifies election state"):
    val scheduled = activeElection.copy(startDate = now.plusSeconds(60))
    val closed    = activeElection.copy(endDate = now)

    assertEquals(ElectionState.from(scheduled, now), ElectionState.Scheduled)
    assertEquals(ElectionState.from(activeElection, now), ElectionState.Active)
    assertEquals(ElectionState.from(closed, now), ElectionState.Closed)

  test("rejects candidate from another election"):
    assertEquals(CastVoteLogic.validate(activeElection, wrongElectionCandidate, now), Left(CandidateNotInElection))

  test("accepts valid vote"):
    assertEquals(CastVoteLogic.validate(activeElection, validCandidate, now), Right(()))

  test("geographic eligibility accepts national elections"):
    val national = activeElection.copy(scope = ElectionScope.National)
    assertEquals(GeographicEligibilityLogic.checkEligibility(voter, national), Right(()))

  test("geographic eligibility accepts matching regional elections"):
    val regional = activeElection.copy(scope = ElectionScope.Regional(Nut3Region.AreaMetropolitanaPorto))
    assertEquals(GeographicEligibilityLogic.checkEligibility(voter, regional), Right(()))

  test("geographic eligibility rejects mismatched regional elections"):
    val regional = activeElection.copy(scope = ElectionScope.Regional(Nut3Region.AreaMetropolitanaLisboa))
    assertEquals(GeographicEligibilityLogic.checkEligibility(voter, regional), Left(VoterNotEligible))
