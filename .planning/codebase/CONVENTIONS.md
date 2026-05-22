# Coding Conventions

**Analysis Date:** 2026-05-21

---

## Languages and Contexts

This project has two distinct codebases with separate conventions:

- **Backend (Scala 3):** `backend/src/main/scala/pt/ipp/estg/elections/`
- **Frontend (Dart/Flutter):** `frontend/lib/`

---

## Backend — Scala 3 Conventions

### Naming Patterns

**Packages:**
- Lowercase, dot-separated: `pt.ipp.estg.election.identity.domain`
- Mirrors directory structure exactly

**Files:**
- `PascalCase.scala` matching the primary type they define
- One primary type per file
- Examples: `Voter.scala`, `RegisterVoterUseCase.scala`, `DoobieVoterRepository.scala`

**Classes and Traits:**
- `PascalCase`
- Use cases: `{Verb}{Noun}UseCase` — e.g., `RegisterVoterUseCase`, `LoginVoterUseCase`
- Algebra traits: `{Verb}{Noun}Alg` — e.g., `RegisterVoterAlg`, `LoginVoterAlg`
- Repository traits: `{Noun}Repository` — e.g., `VoterRepository`, `ElectionRepository`
- Infrastructure implementations: `{Technology}{Noun}Repository` — e.g., `DoobieVoterRepository`, `JwtTokenGenerator`
- AOP wrappers: `{Adjective}{OriginalName}` — e.g., `AuditedLoginUseCase`, `LoggedRegisterVoterUseCase`

**Value wrapper types (newtype pattern):**
- `PascalCase` using `case class Foo(value: T) extends AnyVal`
- Examples: `VoterId`, `CivilId`, `PasswordHash`, `ElectionId`, `ElectionTitle`, `CandidateName`

**Domain error types:**
- Sealed traits: `sealed trait {Domain}Error` — e.g., `sealed trait RegistrationError`
- Error case objects: `PascalCase` descriptive names — e.g., `CivilIdAlreadyExists`, `WeakPassword`, `VoterNotFound`

**Objects (pure logic):**
- `{Noun}Logic` for domain logic objects: `VoterRegistrationLogic`, `VoterLoginLogic`, `CreateElectionLogic`, `AddCandidateLogic`

**Methods:**
- `camelCase`
- Use case entry point is always `execute(...)`: `def execute(...): F[Either[E, A]]`
- Repository methods: `save`, `findById`, `findByCivilId`, `findActive`, `findAll`, `checkExists`

**Variables:**
- `camelCase`
- Type parameters: single uppercase letter `F[_]`, `E`, `A`
- Pipeline variables in for-comprehensions are short and descriptive: `voter`, `exists`, `hashed`, `token`

**GraphQL arguments:**
- `PascalCase` with `Arg` suffix: `CivilIdArg`, `PasswordArg`, `TitleArg`
- Payload case classes: `{Noun}Payload` / `{Noun}ErrorPayload`

### Type System Patterns

**Effect abstraction:** All effectful code is parameterised with `F[_]` and constrained by appropriate type classes:
```scala
class RegisterVoterUseCase[F[_]: Monad](...)
class CreateElectionUseCase[F[_]: Sync](...)
class DoobieVoterRepository[F[_]: MonadCancelThrow](...)
```

**Error representation:** Use `F[Either[DomainError, A]]` — never throw exceptions in domain/application layers:
```scala
def execute(civilIdRaw: String, rawPassword: String, nut3Code: String): F[Either[RegistrationError, Voter]]
```

**EitherT pipelines:** Use `cats.data.EitherT` to sequence effectful operations that may fail:
```scala
val pipeline = for {
  validInputs <- EitherT.fromEither[F](Voter.validateFormat(...))
  exists      <- EitherT.liftF(checkCivilIdExists(civilId))
  _           <- EitherT.cond[F](!exists, (), CivilIdAlreadyExists: RegistrationError)
  hashed      <- EitherT.liftF(hashPassword(validPassword))
} yield Voter(...)
pipeline.value
```

**Domain validation:** Pure `Either` for synchronous checks (no `F[_]` required):
```scala
def validate(...): Either[ElectionError, (ElectionTitle, Instant, Instant)] =
  for {
    _ <- Either.cond(title.trim.length >= 3, (), TitleTooShort: ElectionError)
    _ <- Either.cond(endDate.isAfter(startDate), (), EndDateBeforeStartDate: ElectionError)
  } yield (ElectionTitle(title.trim), startDate, endDate)
```

**Dependency injection via constructor parameters:** No framework — pass dependencies explicitly:
```scala
class LoginVoterUseCase[F[_]: Monad](
  repository:     VoterRepository[F],
  verifier:       PasswordVerifier[F],
  tokenGenerator: TokenGenerator[F]
) extends LoginVoterAlg[F]
```

**AOP pattern (Decorator):** Cross-cutting concerns (audit, logging) are applied by wrapping `Alg` traits, not by modifying use cases:
```scala
final class AuditedLoginUseCase[F[_]: FlatMap](
  target:   LoginVoterAlg[F],
  auditLog: AuditLogAlg[F]
) extends LoginVoterAlg[F] {
  def execute(...) = target.execute(...).flatTap { ... }
}
```
Wired in `Main.scala` by composing: `baseUseCase → auditedUseCase → loggedUseCase`.

### Code Style

**Formatting:**
- No automatic formatter configured (no `.scalafmt.conf` detected)
- Align constructor parameters and case class fields vertically when multi-line:
  ```scala
  case class Voter(
    id:         VoterId,
    civilId:    CivilId,
    password:   PasswordHash,
    nut3Region: Nut3Region,
    isAdmin:    Boolean = false
  )
  ```

**Scala 3 syntax:**
- New-style `enum` for domain enumerations: `enum Nut3Region(val code: String, val label: String)`
- Indentation-based syntax in `object`/`class` bodies using colon (`:`) syntax for extends
- Both `{ }` brace style (in class bodies with `def`) and colon-indentation style are used; files lean towards brace style for class bodies

**scalacOptions enforced (`build.sbt`):**
```
-deprecation, -feature, -unchecked
```

### Import Organization

No strict enforced order, but the observed pattern is:

1. Scala standard library (`java.*`, `scala.*`)
2. Third-party libraries (cats, doobie, sangria, etc.)
3. Project-internal imports (`pt.ipp.estg.election.*`)

Wildcard imports (`._`) are used for doobie implicits and cats syntax:
```scala
import cats.syntax.all._
import doobie.implicits._
import doobie.postgres.implicits._
```

### Error Handling

**Domain/application layer:** Return `F[Either[DomainError, A]]`. Do not throw.

**Infrastructure layer:** Doobie SQL failures propagate as `F` failures (MonadThrow). No manual catching in repository implementations.

**GraphQL layer (`MutationType.scala`):** Exhaustive pattern match on `Either` result, returning error payload types:
```scala
case Right(voter)               => voter
case Left(CivilIdAlreadyExists) => RegistrationErrorPayload("...")
case Left(InvalidCivilIdFormat) => RegistrationErrorPayload("...")
```
Use `.handleError(...)` for IO-level failures (e.g., UUID parse, date parse).

**AOP layer:** Use `.flatTap { ... }` to perform side effects (logging, audit) without altering the result.

### Logging

**Framework:** `log4cats-slf4j` with `LoggerFactory[F]`

**Patterns:**
- `logger.info(s"[AUDIT] REGISTER_SUCCESS civilId=$civilIdRaw voterId=${voter.id.value}")` — structured log line with `[AUDIT]` prefix for audit events
- `logger.warn(...)` for failed audit events
- `[AOP]` prefix for aspect-logging entries: `[AOP] START`, `[AOP] END`, `[AOP] ERROR`
- Logger obtained via `Slf4jLogger.getLoggerFromName[IO]("audit.identity.register")`

### Module Design

**Algebra traits:** Every use case has a companion `Alg` trait defining the interface. This enables decoration and testing:
- `RegisterVoterAlg` → `RegisterVoterUseCase` (implementation)
- The trait is always in `application/` alongside the implementation

**Repository traits:** Defined in `domain/`, implemented in `infrastructure/`

**Logic objects:** Pure stateless `object` in `domain/` containing validation and business rules. Receives effectful callbacks as function parameters instead of dependencies:
```scala
object VoterRegistrationLogic {
  def registerVoter[F[_]: Monad](...)(
    checkCivilIdExists: CivilId => F[Boolean],
    hashPassword:       String  => F[PasswordHash]
  ): F[Either[RegistrationError, Voter]]
}
```

---

## Frontend — Dart/Flutter Conventions

### Naming Patterns

**Files:**
- `snake_case.dart`
- Screens: `{noun}_screen.dart` — e.g., `login_screen.dart`, `active_elections_screen.dart`
- Services: `{noun}_service.dart` — e.g., `auth_service.dart`, `election_service.dart`
- Core utilities: `{noun}.dart` — e.g., `auth_store.dart`, `graphql_service.dart`

**Classes:**
- `PascalCase`
- Public screen widgets: `{Name}Screen` — e.g., `LoginScreen`, `ActiveElectionsScreen`
- Private widget helpers within a file: `_PascalCase` (underscore prefix) — e.g., `_ElectionsHeader`, `_ErrorState`, `_EditorialField`
- State classes: `_{Name}State` — e.g., `_LoginScreenState`, `_ActiveElectionsScreenState`
- Result sealed classes: `{Noun}Result` / `{Verb}Result` — e.g., `LoginResult`, `CreateElectionResult`
- Result variants: `{Noun}Success` / `{Noun}Failure` — e.g., `LoginSuccess`, `LoginFailure`

**Variables and fields:**
- `camelCase`
- Form controllers: `_{noun}Ctrl` — e.g., `_civilIdCtrl`, `_passwordCtrl`
- Services in widgets: `_service` (single instance)
- Loading state: `_isLoading`
- Error message: `_errorMessage`
- Private fields use underscore prefix

**Constants:**
- `lowerCamelCase` for local constants: `const _nut3Regions = [...]`

### Result / Union Type Pattern

Services return sealed classes instead of throwing exceptions:
```dart
sealed class LoginResult {}
final class LoginSuccess extends LoginResult { ... }
final class LoginFailure extends LoginResult { ... }
```

Callers use Dart 3 switch pattern matching:
```dart
switch (result) {
  case LoginSuccess(:final token, :final isAdmin): ...
  case LoginFailure(:final message): ...
}
```

### Data Models

Data objects are plain classes with named parameters and factory constructors:
```dart
class ElectionItem {
  ElectionItem({required this.id, required this.title, ...});
  final String id;
  ...
  factory ElectionItem.fromJson(Map<String, dynamic> json) => ElectionItem(...)
}
```

### Code Style

**Formatting:** Dart standard formatter (`dart format`). `flutter_lints` is configured as dev dependency (`flutter_lints: ^5.0.0`).

**Widget organisation:** Within a single screen file, private helper widgets are defined after the main screen class, separated by section comments:
```dart
// ── Header ────────────────────────────────────────────────────────────────────
class _SomeSectionWidget extends StatelessWidget { ... }
```

**`const` constructors:** Used everywhere possible for `StatelessWidget` subclasses:
```dart
const ActiveElectionsScreen({super.key});
```

**`super.key` pattern:** All public widgets pass `super.key` in constructors.

**`mounted` checks:** Always check `if (!mounted) return;` after any `await` in `StatefulWidget` methods that call `setState`.

### Import Organization

All imports use full package paths:
```dart
import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';
import 'package:sistema_eleitoral_frontend/features/election/data/election_service.dart';
```

No relative imports (`../`) are used. Package prefix is always `sistema_eleitoral_frontend`.

Order observed:
1. Flutter SDK (`flutter/material.dart`)
2. Third-party packages (`google_fonts`, `http`)
3. Internal `core/` imports
4. Internal `features/` imports

### Error Handling

**Network errors:** Service methods are wrapped in `try/catch`. Network-level exceptions are caught and converted to user-facing strings:
```dart
} catch (_) {
  setState(() => _errorMessage = 'Erro de ligação ao servidor.');
}
```

**GraphQL errors:** `GraphQLService.execute()` throws `Exception` when GraphQL `errors` array is non-empty. Callers use the `catch` block in `_submit()`.

**Application-level errors:** Expressed as `sealed class` result types (never thrown from service methods).

**UI error display:** Use the reusable `_ErrorBanner` widget (defined per-screen) to surface `_errorMessage` inline in forms.

### State Management

**No state management library.** State is local to `StatefulWidget` using `setState`.

**Global auth state:** Single-instance singleton: `AuthStore.instance` (in `frontend/lib/core/auth/auth_store.dart`). Not reactive — consumers call `setState` after mutating it.

**Async data loading:** Use `FutureBuilder<T>` with a `late Future<T> _future` field assigned in `initState`:
```dart
late Future<List<ElectionItem>> _future;

@override
void initState() {
  super.initState();
  _future = _service.listAllElections();
}
```

Refresh pattern: reassign `_future` inside `setState`:
```dart
void _refresh() => setState(() => _future = _service.listAllElections());
```

### Service Instantiation

Services are instantiated directly inside widget state classes (not injected):
```dart
final _service = ElectionService(
  GraphQLService(baseUrl: 'http://localhost:8080/graphql'),
);
```

The base URL `http://localhost:8080/graphql` is hardcoded in every screen. This is a known limitation — see `CONCERNS.md`.

### Widget Design

**Decompose screens** into private `StatelessWidget` subclasses for distinct sections (header, list, empty state, error state, footer).

**Shared UI components** (e.g., `_ErrorBanner`, `_EditorialField`, `_EditorialHeader`) are defined at the bottom of the screen file they originate in and are not extracted to a separate shared widget file — they are duplicated across files.

**Navigation:** Named routes via `Navigator.pushNamed(context, '/route', arguments: ...)`. Arguments passed as typed objects (e.g., `ElectionItem`).

### Comments

**Section dividers** in Dart files use the pattern:
```dart
// ── Section Name ──────────────────────────────────────────────────────────────
```

**Inline comments:** Sparse, only for non-obvious logic.

---

*Convention analysis: 2026-05-21*
