package pt.ipp.estg.election

import cats.effect.IO
import munit.CatsEffectSuite
import pt.ipp.estg.election.identity.application._
import pt.ipp.estg.election.identity.domain._

class RegisterVoterUseCaseSuite extends CatsEffectSuite:

  class StubVoterRepository(existingIds: Set[String]) extends VoterRepository[IO]:
    def checkExists(civilId: CivilId): IO[Boolean]         = IO.pure(existingIds.contains(civilId.value))
    def save(voter: Voter): IO[Unit]                        = IO.unit
    def findByCivilId(civilId: CivilId): IO[Option[Voter]] = IO.pure(None)
    def findById(id: VoterId): IO[Option[Voter]]           = IO.pure(None)

  class StubPasswordHasher extends PasswordHasher[IO]:
    def hash(rawPassword: String): IO[PasswordHash] = IO.pure(PasswordHash(s"hashed:$rawPassword"))

  private def makeUseCase(existingIds: Set[String] = Set.empty): RegisterVoterUseCase[IO] =
    new RegisterVoterUseCase[IO](new StubVoterRepository(existingIds), new StubPasswordHasher)

  test("regista eleitor com dados válidos"):
    makeUseCase().execute("12345678", "password123", "cavado").map: result =>
      assert(result.isRight)

  test("rejeita civil_id já registado"):
    makeUseCase(existingIds = Set("12345678")).execute("12345678", "password123", "cavado").map: result =>
      assertEquals(result, Left(CivilIdAlreadyExists))

  test("rejeita civil_id com formato inválido (menos de 8 caracteres)"):
    makeUseCase().execute("1234", "password123", "cavado").map: result =>
      assertEquals(result, Left(InvalidCivilIdFormat))

  test("rejeita password fraca (menos de 8 caracteres)"):
    makeUseCase().execute("12345678", "weak", "cavado").map: result =>
      assertEquals(result, Left(WeakPassword))
