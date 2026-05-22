package pt.ipp.estg.election

import java.time.Instant
import java.util.UUID
import pt.ipp.estg.election.election.domain._
import pt.ipp.estg.election.identity.domain.VoterId
import pt.ipp.estg.election.voting.domain._

class CastVoteLogicSuite extends munit.FunSuite:

  val now: Instant = Instant.parse("2026-05-21T12:00:00Z")

  val electionId: ElectionId = ElectionId(UUID.randomUUID())
  val otherId:    ElectionId = ElectionId(UUID.randomUUID())

  val activeElection: Election = Election(
    id        = electionId,
    title     = ElectionTitle("Eleição Teste"),
    startDate = now.minusSeconds(3600),
    endDate   = now.plusSeconds(3600)
  )

  val candidateId: CandidateId = CandidateId(UUID.randomUUID())

  val validCandidate: Candidate = Candidate(
    id         = candidateId,
    electionId = electionId,
    name       = CandidateName("Candidato A"),
    party      = None,
    photoUrl   = None,
    number     = 1
  )

  val wrongElectionCandidate: Candidate = validCandidate.copy(electionId = otherId)

  test("rejeita voto quando eleição ainda não começou"):
    val notStarted = activeElection.copy(startDate = now.plusSeconds(60))
    assertEquals(CastVoteLogic.validate(notStarted, validCandidate, now), Left(ElectionNotActive))

  test("rejeita voto quando eleição já terminou"):
    val ended = activeElection.copy(endDate = now.minusSeconds(60))
    assertEquals(CastVoteLogic.validate(ended, validCandidate, now), Left(ElectionNotActive))

  test("aceita voto no instante exato de início"):
    val atStart = activeElection.copy(startDate = now)
    assertEquals(CastVoteLogic.validate(atStart, validCandidate, now), Right(()))

  test("rejeita candidato que não pertence à eleição"):
    assertEquals(CastVoteLogic.validate(activeElection, wrongElectionCandidate, now), Left(CandidateNotInElection))

  test("aceita voto válido"):
    assertEquals(CastVoteLogic.validate(activeElection, validCandidate, now), Right(()))
