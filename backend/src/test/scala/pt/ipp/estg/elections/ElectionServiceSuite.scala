package pt.ipp.estg.elections

import cats.effect.IO
import munit.CatsEffectSuite
import pt.ipp.estg.elections.domain.*
import pt.ipp.estg.elections.infra.{EventBus, InMemoryRepository}
import pt.ipp.estg.elections.services.ElectionService
import java.util.UUID

class ElectionServiceSuite extends CatsEffectSuite:
  test("eleitor elegível consegue votar uma única vez") {
    val e = ElectionId(UUID.fromString("11111111-1111-1111-1111-111111111111"))
    val c = CandidateId(UUID.fromString("22222222-2222-2222-2222-222222222222"))
    val voter = Voter(VoterId("12345678"), "Ana Silva", Set(e), Set.empty)
    for
      repo <- InMemoryRepository.create[IO]
      bus <- EventBus.create[IO]
      service = ElectionService[IO](repo, bus)
      voterRegistration <- service.registerVoter(voter)
      first <- service.vote(voter.id, e, c)
      second <- service.vote(voter.id, e, c)
    yield
      val registrationCompleted = voterRegistration
      assertEquals(registrationCompleted, ())
      assert(first.isRight)
      assert(second.isLeft)
  }
