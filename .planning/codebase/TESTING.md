# Testing Patterns

**Analysis Date:** 2026-05-21

---

## Overview

Testing exists only in the **backend**. The frontend has no test files.

---

## Backend — Test Framework

**Runner:**
- MUnit 1.1.0
- Config: `build.sbt` — `"org.scalameta" %% "munit" % "1.1.0" % Test`

**Async extension:**
- munit-cats-effect 2.0.0
- Config: `"org.typelevel" %% "munit-cats-effect" % "2.0.0" % Test`
- Base class: `munit.CatsEffectSuite`

**Assertion Library:**
- MUnit built-ins: `assert(...)`, `assertEquals(..., ...)`

**Run Commands:**
```bash
sbt test          # Run all tests
sbt ~test         # Watch mode (re-run on file change)
sbt testOnly *SuiteName   # Run a specific suite
```

---

## Test File Organisation

**Location:** `backend/src/test/scala/pt/ipp/estg/elections/`

**Naming:** `{FeatureName}Suite.scala` — e.g., `ElectionServiceSuite.scala`

**Current coverage:**
- `backend/src/test/scala/pt/ipp/estg/elections/ElectionServiceSuite.scala` — tests `RegisterVoterUseCase` via stubs

**Package declaration in test file (note discrepancy):**
- Source package: `pt.ipp.estg.election` (without the `s` in elections)
- Test file uses: `package pt.ipp.estg.election`
- All imports also use `pt.ipp.estg.election.*`

---

## Test Structure

**Suite class declaration:**
```scala
class RegisterVoterUseCaseSuite extends CatsEffectSuite:
```

**Pattern:** All tests in a suite are defined using `test("description"):` with a descriptive Portuguese-language description:
```scala
test("regista eleitor com dados válidos"):
  makeUseCase().execute("12345678", "password123").map: result =>
    assert(result.isRight)

test("rejeita civil_id já registado"):
  makeUseCase(existingIds = Set("12345678")).execute("12345678", "password123").map: result =>
    assertEquals(result, Left(CivilIdAlreadyExists))
```

**`CatsEffectSuite` async pattern:** Test body returns `IO[Unit]` (or `IO[Assertion]`). MUnit-cats-effect handles running the IO. No `unsafeRunSync` is used in tests.

**Setup:** No `beforeEach`/`afterEach` hooks. Test helpers are constructed inline via factory methods.

---

## Mocking

**Framework:** No mocking library. All test doubles are hand-written `Stub` inner classes.

**Pattern:** Stub classes are defined inside the suite class, implementing the algebra/repository trait:
```scala
class StubVoterRepository(existingIds: Set[String]) extends VoterRepository[IO]:
  def checkExists(civilId: CivilId): IO[Boolean] = IO.pure(existingIds.contains(civilId.value))
  def save(voter: Voter): IO[Unit]                = IO.unit

class StubPasswordHasher extends PasswordHasher[IO]:
  def hash(rawPassword: String): IO[PasswordHash] = IO.pure(PasswordHash(s"hashed:$rawPassword"))
```

**Factory helper method pattern:** A `private def makeUseCase(...)` method constructs the use case with stubs for each test scenario:
```scala
private def makeUseCase(existingIds: Set[String] = Set.empty): RegisterVoterUseCase[IO] =
  new RegisterVoterUseCase[IO](new StubVoterRepository(existingIds), new StubPasswordHasher)
```

**What to stub:**
- Repository traits (`VoterRepository[IO]`, `ElectionRepository[IO]`, etc.)
- Port traits (`PasswordHasher[IO]`, `TokenGenerator[IO]`, etc.)
- All IO-producing dependencies from the `application/` layer

**What NOT to stub:**
- Domain logic objects (`VoterRegistrationLogic`, `VoterLoginLogic`, etc.) — these are pure and tested indirectly through the use case
- `IO` itself — use real `cats.effect.IO` in tests, not a mock effect type

---

## Test Design Philosophy

**Unit test scope:** Each test suite targets a single use case class. The use case is exercised through its `execute(...)` method (the public interface defined by the `Alg` trait).

**Scenario-based tests:** Each test case represents one business scenario, named in plain language. The same use case is tested with different stub configurations:
- Happy path: valid inputs → `Right(result)`
- Duplicate check: existing ID → `Left(CivilIdAlreadyExists)`
- Format validation: short ID → `Left(InvalidCivilIdFormat)`
- Weak credentials: short password → `Left(WeakPassword)`

**Domain error assertions:** Use `assertEquals(result, Left(SpecificError))` to assert on typed domain errors — never assert on error message strings.

**Success assertions:** Use `assert(result.isRight)` for happy path when the exact value is not critical, or destructure with `assertEquals`.

---

## Coverage

**Requirements:** None enforced via build configuration.

**Current state:**
- `RegisterVoterUseCase` — 4 tests covering the main scenarios
- All other use cases (`LoginVoterUseCase`, `CreateElectionUseCase`, `AddCandidateUseCase`, election listing) — **no tests**
- Domain logic objects (`VoterRegistrationLogic`, `VoterLoginLogic`, `CreateElectionLogic`, `AddCandidateLogic`) — only tested indirectly via `RegisterVoterUseCase`
- Infrastructure layer (Doobie repositories, JWT, Bcrypt) — **no tests**
- AOP wrappers (`AuditedLoginUseCase`, `LoggedRegisterVoterUseCase`) — **no tests**

**View coverage:**
```bash
sbt coverageReport   # Requires sbt-scoverage plugin (not currently configured)
```
Coverage plugin is not present in `build.sbt`.

---

## Test Types

**Unit Tests:**
- Location: `backend/src/test/scala/`
- Scope: Single use case with all dependencies stubbed
- Tools: MUnit + munit-cats-effect + hand-written stubs

**Integration Tests:**
- Not present. No database or HTTP layer tests exist.

**E2E Tests:**
- Not present for either backend or frontend.

---

## Frontend Testing

**Framework declared:** `flutter_test` (Flutter SDK built-in) — listed as dev dependency in `frontend/pubspec.yaml`

**Linting:** `flutter_lints: ^5.0.0` — enforces Dart best practices via analysis

**Test files:** None exist. The `test/` directory for Flutter is not populated.

---

## Adding New Tests

**New backend use case test:**

1. Create `backend/src/test/scala/pt/ipp/estg/elections/{FeatureName}Suite.scala`
2. Declare `package pt.ipp.estg.election`
3. Extend `munit.CatsEffectSuite`
4. Define inner `Stub` classes implementing the required algebra traits
5. Write a `private def makeUseCase(...)` factory
6. Write `test("scenario description"):` blocks that return `IO[Unit]`

Example template:
```scala
package pt.ipp.estg.election

import cats.effect.IO
import munit.CatsEffectSuite
import pt.ipp.estg.election.election.application._
import pt.ipp.estg.election.election.domain._

class CreateElectionUseCaseSuite extends CatsEffectSuite:

  class StubElectionRepository extends ElectionRepository[IO]:
    def save(election: Election): IO[Unit]           = IO.unit
    def findById(id: ElectionId): IO[Option[Election]] = IO.pure(None)
    def findActive(now: java.time.Instant): IO[List[Election]] = IO.pure(Nil)
    def findAll(): IO[List[Election]]                = IO.pure(Nil)

  private def makeUseCase(): CreateElectionUseCase[IO] =
    new CreateElectionUseCase[IO](new StubElectionRepository)

  test("cria eleição com dados válidos"):
    val start = java.time.Instant.now().plusSeconds(60)
    val end   = start.plusSeconds(3600)
    makeUseCase().execute("Eleição Presidencial", start, end).map: result =>
      assert(result.isRight)

  test("rejeita título demasiado curto"):
    val start = java.time.Instant.now().plusSeconds(60)
    val end   = start.plusSeconds(3600)
    makeUseCase().execute("AB", start, end).map: result =>
      assertEquals(result, Left(TitleTooShort))
```

---

*Testing analysis: 2026-05-21*
