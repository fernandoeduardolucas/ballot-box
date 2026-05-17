package pt.ipp.estg.election

import cats.effect.{IO, Ref}
import munit.CatsEffectSuite
import pt.ipp.estg.election.identity.application.{PasswordHasher, RegisterVoterUseCase}
import pt.ipp.estg.election.identity.domain.*

/** Behaviour tests for voter registration. */
class ElectionServiceSuite extends CatsEffectSuite:
  test("registers a voter once and rejects duplicate civil IDs") {
    for
      savedCivilIds <- Ref.of[IO, Set[CivilId]](Set.empty)
      repository = new InMemoryVoterRepository(savedCivilIds)
      useCase = new RegisterVoterUseCase[IO](repository, DeterministicPasswordHasher)
      first <- useCase.execute("12345678", "strong-password")
      second <- useCase.execute("12345678", "strong-password")
    yield
      assert(first.isRight)
      assertEquals(second, Left(CivilIdAlreadyExists))
  }

  test("rejects weak passwords before persisting voters") {
    for
      savedCivilIds <- Ref.of[IO, Set[CivilId]](Set.empty)
      repository = new InMemoryVoterRepository(savedCivilIds)
      useCase = new RegisterVoterUseCase[IO](repository, DeterministicPasswordHasher)
      result <- useCase.execute("12345678", "weak")
      persisted <- savedCivilIds.get
    yield
      assertEquals(result, Left(WeakPassword))
      assert(persisted.isEmpty)
  }

private final class InMemoryVoterRepository(savedCivilIds: Ref[IO, Set[CivilId]]) extends VoterRepository[IO]:
  def checkExists(civilId: CivilId): IO[Boolean] =
    savedCivilIds.get.map(_.contains(civilId))

  def save(voter: Voter): IO[Unit] =
    savedCivilIds.update(_ + voter.civilId)

private object DeterministicPasswordHasher extends PasswordHasher[IO]:
  def hash(rawPassword: String): IO[PasswordHash] =
    IO.pure(PasswordHash(s"hashed:$rawPassword"))
