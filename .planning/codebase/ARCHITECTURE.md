<!-- refreshed: 2026-05-21 -->
# Architecture

**Analysis Date:** 2026-05-21

## System Overview

```text
┌──────────────────────────────────────────────────────────────────────┐
│                     Flutter Frontend (web/mobile)                     │
│   `frontend/lib/features/*/presentation/screens/`                    │
│                                                                       │
│   ActiveElectionsScreen · ElectionDetailScreen · VoteScreen          │
│   LoginScreen · CreateElectionScreen · AddCandidateScreen            │
└─────────────┬───────────────────────────────────┬────────────────────┘
              │ HTTP/JSON (GraphQL over POST)       │ Bearer JWT
              ▼                                     ▼
┌──────────────────────────────────────────────────────────────────────┐
│          Backend Interface Adapters (API Layer)                       │
│                                                                       │
│   GraphQL Schema     QueryType            MutationType                │
│   `api/graphql/schemas/`  `api/graphql/QueryType.scala`              │
│                        `api/graphql/MutationType.scala`              │
│                                                                       │
│   Request context assembled per-request in ElectionContext           │
│   `api/graphql/ElectionContext.scala`                                │
└─────────────────────────────┬────────────────────────────────────────┘
                              │ Alg[F[_]] traits (dependency inversion)
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│          Application Layer  (Use Cases + AOP Decorators)             │
│                                                                       │
│  identity/application/         election/application/                 │
│    RegisterVoterUseCase          CreateElectionUseCase               │
│    LoginVoterUseCase             AddCandidateUseCase                 │
│                                  ListActiveElectionsUseCase          │
│                                  ListAllElectionsUseCase             │
│  aop/                            ListElectionCandidatesUseCase       │
│    AuditedLoginUseCase                                               │
│    AuditedRegisterVoterUseCase                                       │
│    LoggedRegisterVoterUseCase                                        │
└──────────────┬───────────────────────────────────────────────────────┘
               │ delegates to domain logic functions + repository traits
               ▼
┌──────────────────────────────────────────────────────────────────────┐
│          Domain Layer  (Pure business logic — no F[_] effects)       │
│                                                                       │
│  identity/domain/              election/domain/                      │
│    Voter, CivilId, VoterId       Election, ElectionId, ElectionTitle │
│    AuthToken, AuthenticatedVoter Candidate, CandidateId              │
│    Nut3Region (enum, 25 regions) ElectionRepository[F[_]] trait      │
│    VoterRepository[F[_]] trait   CandidateRepository[F[_]] trait    │
│    VoterRegistrationLogic        CreateElectionLogic                 │
│    VoterLoginLogic               AddCandidateLogic                   │
│    RegistrationError (sealed)    ElectionError (sealed)              │
│    LoginError (sealed)           CandidateError (sealed)            │
└──────────────┬───────────────────────────────────────────────────────┘
               │ trait implementations
               ▼
┌──────────────────────────────────────────────────────────────────────┐
│          Infrastructure Layer  (Doobie/JDBC, BCrypt, JWT)            │
│                                                                       │
│  identity/infrastructure/      election/infrastructure/              │
│    DoobieVoterRepository         DoobieElectionRepository            │
│    DoobieAuditLogRepository      DoobieCandidateRepository           │
│    BcryptPasswordHasher                                              │
│    BcryptPasswordVerifier                                            │
│    JwtTokenGenerator                                                 │
│    JwtTokenVerifier                                                  │
└──────────────┬───────────────────────────────────────────────────────┘
               │ JDBC / Flyway migrations
               ▼
┌──────────────────────────────────────────────────────────────────────┐
│          PostgreSQL 16                                                │
│  Tables: voters · elections · candidates · audit_log                 │
│  Migrations: `src/main/resources/db/migration/V1–V6__*.sql`         │
└──────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `Main` | Wires all dependencies, runs Flyway, starts http4s/Ember server | `backend/src/main/scala/pt/ipp/estg/elections/Main.scala` |
| `ElectionContext` | Per-request context carrying all use-case Algs + auth | `backend/.../api/graphql/ElectionContext.scala` |
| `QueryType` | Sangria GraphQL query field definitions | `backend/.../api/graphql/QueryType.scala` |
| `MutationType` | Sangria GraphQL mutation field definitions | `backend/.../api/graphql/MutationType.scala` |
| `ElectionSchema` | Election/Candidate Sangria type definitions | `backend/.../api/graphql/schemas/ElectionSchema.scala` |
| `IdentitySchema` | Voter/Login/Register Sangria type definitions | `backend/.../api/graphql/schemas/IdentitySchema.scala` |
| `RegisterVoterAlg[F]` | Use-case algebra trait for voter registration | `backend/.../identity/application/RegisterVoterAlg.scala` |
| `RegisterVoterUseCase` | Orchestrates domain logic + persistence for voter registration | `backend/.../identity/application/RegisterVoterUseCase.scala` |
| `LoginVoterAlg[F]` | Use-case algebra trait for voter login | `backend/.../identity/application/LoginVoterAlg.scala` |
| `LoginVoterUseCase` | Orchestrates domain logic + persistence for login | `backend/.../identity/application/LoginVoterUseCase.scala` |
| `VoterRegistrationLogic` | Pure domain logic for registration validation pipeline | `backend/.../identity/domain/VoterRegistrationLogic.scala` |
| `VoterLoginLogic` | Pure domain logic for login validation pipeline | `backend/.../identity/domain/VoterLoginLogic.scala` |
| `CreateElectionUseCase` | Orchestrates election creation via domain logic | `backend/.../election/application/CreateElectionUseCase.scala` |
| `AddCandidateUseCase` | Validates and persists candidates linked to elections | `backend/.../election/application/AddCandidateUseCase.scala` |
| `CreateElectionLogic` | Pure domain validation for election creation | `backend/.../election/domain/CreateElectionLogic.scala` |
| `AddCandidateLogic` | Pure domain validation for candidate addition | `backend/.../election/domain/AddCandidateLogic.scala` |
| `AuditedLoginUseCase` | Decorator: wraps `LoginVoterAlg` with DB audit logging | `backend/.../aop/AuditedLoginUseCase.scala` |
| `AuditedRegisterVoterUseCase` | Decorator: wraps `RegisterVoterAlg` with SLF4J audit logging | `backend/.../aop/AuditAspect.scala` |
| `LoggedRegisterVoterUseCase` | Decorator: wraps `RegisterVoterAlg` with timing/logging via LoggingAspect | `backend/.../aop/LoggingAspect.scala` |
| `DoobieVoterRepository` | JDBC implementation of `VoterRepository[F]` | `backend/.../identity/infrastructure/DoobieVoterRepository.scala` |
| `DoobieElectionRepository` | JDBC implementation of `ElectionRepository[F]` | `backend/.../election/infrastructure/DoobieElectionRepository.scala` |
| `DoobieCandidateRepository` | JDBC implementation of `CandidateRepository[F]` | `backend/.../election/infrastructure/DoobieCandidateRepository.scala` |
| `DoobieAuditLogRepository` | JDBC implementation of `AuditLogAlg[F]` | `backend/.../identity/infrastructure/DoobieAuditLogRepository.scala` |
| `JwtTokenGenerator` | Issues HS256 JWT with voter claims | `backend/.../identity/infrastructure/JwtTokenGenerator.scala` |
| `JwtTokenVerifier` | Decodes and validates JWT, produces `Option[AuthenticatedVoter]` | `backend/.../identity/infrastructure/JwtTokenVerifier.scala` |
| `BcryptPasswordHasher` | BCrypt password hashing (work factor 12) | `backend/.../identity/infrastructure/BcryptPasswordHasher.scala` |
| `BcryptPasswordVerifier` | BCrypt password verification | `backend/.../identity/infrastructure/BcryptPasswordVerifier.scala` |
| `AppConfig` | Typesafe config loading via PureConfig (HOCON) | `backend/.../config/AppConfig.scala` |
| `GraphQLService` | HTTP client wrapper sending GraphQL requests | `frontend/lib/core/services/graphql_service.dart` |
| `AuthStore` | Singleton in-memory JWT store (`isAuthenticated`, `isAdmin`) | `frontend/lib/core/auth/auth_store.dart` |
| `ElectionService` | Sends election GraphQL queries/mutations; parses results | `frontend/lib/features/election/data/election_service.dart` |
| `CandidateService` | Sends candidate GraphQL mutations; parses results | `frontend/lib/features/election/data/candidate_service.dart` |
| `AuthService` | Sends login/register GraphQL mutations; parses results | `frontend/lib/features/identity/data/auth_service.dart` |

## Pattern Overview

**Overall:** Clean Architecture with Tagless Final (higher-kinded type `F[_]`) and Decorator pattern for cross-cutting concerns

**Key Characteristics:**
- All domain interfaces (repository traits, use-case Alg traits) are parameterised by `F[_]`, making them independent of the effect system
- Concrete implementations for `F = IO` (Cats Effect) are wired exclusively in `Main.scala`
- Domain logic objects (`VoterRegistrationLogic`, `VoterLoginLogic`, `CreateElectionLogic`, `AddCandidateLogic`) are pure functions using `EitherT` pipelines — no infrastructure dependencies
- Decorator chain wraps use-cases: base use-case → audit decorator → logging decorator; each decorator implements the same Alg trait
- Error handling is typed: each bounded context has its own `sealed trait` error ADT; never throws

## Layers

**Interface Adapters (API):**
- Purpose: Translate HTTP/GraphQL requests into use-case calls; translate results to GraphQL response types
- Location: `backend/src/main/scala/pt/ipp/estg/elections/api/`
- Contains: Sangria schema definitions, GraphQL query/mutation resolvers, `ElectionContext` request carrier
- Depends on: Application layer Alg traits only
- Used by: http4s router in `Main.scala`

**Application Layer (Use Cases):**
- Purpose: Orchestrate domain logic calls and persistence; implement Alg traits
- Location: `backend/src/main/scala/pt/ipp/estg/elections/{identity,election}/application/`
- Contains: `*UseCase` classes, `*Alg` traits, `PasswordHasher`, `PasswordVerifier`, `TokenGenerator`, `TokenVerifier` port traits
- Depends on: Domain layer entities and repository traits; application-level port traits
- Used by: API layer via `ElectionContext`; also by AOP decorators in `aop/`

**AOP / Decorator Layer:**
- Purpose: Add cross-cutting behaviour (audit logging, timing/logging) without modifying use-case logic
- Location: `backend/src/main/scala/pt/ipp/estg/elections/aop/`
- Contains: `AuditedLoginUseCase`, `AuditedRegisterVoterUseCase`, `LoggedRegisterVoterUseCase`, `LoggingAspect`, `AuditLogAlg[F]` trait, `AuditEvent` model
- Depends on: Application layer Alg traits
- Used by: `Main.scala` when constructing the decorator chains

**Domain Layer:**
- Purpose: Pure business rules and entity definitions; zero infrastructure dependencies
- Location: `backend/src/main/scala/pt/ipp/estg/elections/{identity,election}/domain/`
- Contains: Value objects (`ElectionId`, `VoterId`, etc.), aggregate roots (`Voter`, `Election`, `Candidate`), domain logic objects, repository trait interfaces, error ADTs, `Nut3Region` enum
- Depends on: Nothing outside Cats core; no infrastructure or I/O
- Used by: Application layer

**Infrastructure Layer:**
- Purpose: Implement domain repository traits using external libraries (Doobie, BCrypt, JWT)
- Location: `backend/src/main/scala/pt/ipp/estg/elections/{identity,election}/infrastructure/`
- Contains: `Doobie*Repository` classes, `BcryptPassword*`, `JwtToken*`
- Depends on: Domain traits; Doobie, org.mindrot.jbcrypt, pdi.jwt
- Used by: `Main.scala` wiring only

**Frontend Feature Modules:**
- Purpose: Each feature (`election`, `identity`) has `data/` (service) and `presentation/screens/` sub-layers
- Location: `frontend/lib/features/{election,identity}/`
- Contains: Data services calling `GraphQLService`; Flutter `StatefulWidget` screens
- Depends on: `core/services/graphql_service.dart`, `core/auth/auth_store.dart`
- Used by: Routes declared in `frontend/lib/main.dart`

## Data Flow

### Voter Registration (Mutation)

1. Flutter `RegisterScreen` calls `AuthService.register()` (`frontend/lib/features/identity/data/auth_service.dart`)
2. `AuthService` calls `GraphQLService.execute()` with `registerVoter` mutation (`frontend/lib/core/services/graphql_service.dart`)
3. HTTP POST to `POST /graphql` received by `Main.scala` router
4. `MutationType.Mutation` `registerVoter` field resolver extracts args, calls `ctx.ctx.registerVoterUseCase.execute()` (`api/graphql/MutationType.scala:37-49`)
5. `LoggedRegisterVoterUseCase.execute()` times the call; delegates to `AuditedRegisterVoterUseCase` (`aop/LoggingAspect.scala`)
6. `AuditedRegisterVoterUseCase.execute()` logs audit via SLF4J; delegates to `RegisterVoterUseCase` (`aop/AuditAspect.scala`)
7. `RegisterVoterUseCase.execute()` calls `VoterRegistrationLogic.registerVoter()` with callbacks for existence check and hashing (`identity/application/RegisterVoterUseCase.scala`)
8. `VoterRegistrationLogic` runs `EitherT` pipeline: validate format → check duplicates → hash password → build `Voter` (`identity/domain/VoterRegistrationLogic.scala`)
9. On success, `RegisterVoterUseCase` calls `repository.save(voter)` — executed by `DoobieVoterRepository` (`identity/infrastructure/DoobieVoterRepository.scala`)
10. Result propagated back as `Either[RegistrationError, Voter]`; `MutationType` maps to `RegisterVoterPayload` union type

### Login Flow (Mutation)

1. `AuthService.login()` sends `loginVoter` mutation
2. `MutationType` resolver calls `ctx.ctx.loginVoterUseCase.execute(civilId, password, ip)` — this is `AuditedLoginUseCase`
3. `AuditedLoginUseCase` delegates to `LoginVoterUseCase`, then records `AuditEvent` to `DoobieAuditLogRepository` (`aop/AuditedLoginUseCase.scala`)
4. `LoginVoterUseCase` calls `VoterLoginLogic.login()` with `findVoter`, `verifyPassword`, `generateToken` callbacks
5. `JwtTokenGenerator.generate()` issues HS256 JWT with `sub`, `civilId`, `nut3Region`, `isAdmin` claims
6. Response carries `token` + `isAdmin`; frontend stores in `AuthStore.instance.setSession()`

### JWT Auth (Per-Request)

1. `Main.scala` extracts `Authorization: Bearer <token>` header (`Main.scala:54-59`)
2. Calls `tokenVerifier.verify(rawToken)` — `JwtTokenVerifier` decodes claim, extracts `AuthenticatedVoter`
3. `ElectionContext` receives `Option[AuthenticatedVoter]`
4. Admin-only mutations check `ctx.ctx.authenticatedVoter.exists(_.isAdmin)` inside `MutationType` resolvers

### Election Query (Query)

1. Flutter `ActiveElectionsScreen` calls `ElectionService.listActiveElections()` on `initState()`
2. `GraphQLService` issues `activeElections` query; `QueryType` resolver calls `listActiveElectionsUseCase.execute()`
3. `ListActiveElectionsUseCase` calls `Sync[F].delay(Instant.now())` then `electionRepo.findActive(now)`
4. `DoobieElectionRepository.findActive()` runs parameterised SQL, returns `List[Election]`
5. Resolvers map domain objects to `ElectionPayload` case classes; Sangria serialises to JSON

**State Management (Frontend):**
- No provider/bloc/riverpod — state is local to `StatefulWidget` via `setState()`
- Authentication state held in `AuthStore.instance` singleton across all screens
- GraphQL base URL is hardcoded as `http://localhost:8080/graphql` in each screen that instantiates a service

## Key Abstractions

**Alg traits (use-case interfaces):**
- Purpose: Define the contract of each use case; enable decorator wrapping and testing via substitution
- Examples: `RegisterVoterAlg[F]`, `LoginVoterAlg[F]`, `CreateElectionAlg[F]`, `AddCandidateAlg[F]`, `ListActiveElectionsAlg[F]`, `ListAllElectionsAlg[F]`, `ListElectionCandidatesAlg[F]`
- Pattern: Single `execute(...)` method returning `F[Either[Error, Result]]` or `F[List[Result]]`

**Repository traits (domain ports):**
- Purpose: Describe persistence needs from the domain's perspective; implemented by infrastructure
- Examples: `VoterRepository[F]` (`identity/domain/VoterRepository.scala`), `ElectionRepository[F]` (`election/domain/ElectionRepository.scala`), `CandidateRepository[F]` (`election/domain/CandidateRepository.scala`)
- Pattern: Higher-kinded type `F[_]`; concrete impls use `MonadCancelThrow` or `Sync` constraints

**Domain Logic objects (pure functions):**
- Purpose: Encapsulate business validation rules with no infrastructure dependency
- Examples: `VoterRegistrationLogic` (`identity/domain/VoterRegistrationLogic.scala`), `VoterLoginLogic` (`identity/domain/VoterLoginLogic.scala`), `CreateElectionLogic` (`election/domain/CreateElectionLogic.scala`), `AddCandidateLogic` (`election/domain/AddCandidateLogic.scala`)
- Pattern: Companion objects with `def X[F[_]: Monad](...)(...)(callbacks): F[Either[Error, Result]]` — side effects injected as function parameters

**Error ADTs (sealed traits):**
- Purpose: Type-safe, exhaustive error handling without exceptions
- Examples: `RegistrationError`, `LoginError` (`identity/domain/`), `ElectionError`, `CandidateError` (`election/domain/`)
- Pattern: `sealed trait` with `case object` subtypes; pattern-matched in GraphQL resolvers

**Sealed result types (Flutter):**
- Purpose: Typed outcomes for GraphQL mutation calls
- Examples: `LoginResult`/`LoginSuccess`/`LoginFailure` (`identity/data/auth_service.dart`), `CreateElectionResult` (`election/data/election_service.dart`), `AddCandidateResult` (`election/data/candidate_service.dart`)
- Pattern: Dart `sealed class` — exhaustively switched in UI

**ElectionContext:**
- Purpose: Carries all injected use-case instances + auth state for a single GraphQL request; Sangria's user context
- Location: `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/ElectionContext.scala`
- Pattern: Case class assembled per-request in `Main.scala` router, referenced in every resolver as `ctx.ctx`

## Entry Points

**Backend:**
- Location: `backend/src/main/scala/pt/ipp/estg/elections/Main.scala`
- Triggers: `sbt run`; `Main extends IOApp.Simple`
- Responsibilities: Load `AppConfig`, run Flyway migrations, build `Transactor`, wire all use-case instances and decorators, build Sangria schema, start http4s Ember server

**Frontend:**
- Location: `frontend/lib/main.dart`
- Triggers: Flutter app launch (`void main()`)
- Responsibilities: Configure `MaterialApp` with `ThemeData`, declare named routes, set `ActiveElectionsScreen` as home

## Architectural Constraints

- **Effect system:** All backend effects are `cats.effect.IO`; the code is written generically as `F[_]` but wired to `IO` in `Main.scala` exclusively
- **GraphQL dispatch:** Sangria requires `Future`-based resolvers; bridged via `Dispatcher.unsafeToFuture(...)` on every resolver — this is the only place where `IO` escapes to `Future`
- **JWT secret:** Defaults to `"change-me-in-production"` in `application.conf`; must be overridden via `JWT_SECRET` env var in production
- **Global state (frontend):** `AuthStore` is a module-level singleton; `_token` / `_isAdmin` are mutable fields — not thread-safe (acceptable for single-threaded Dart)
- **Hardcoded backend URL:** `GraphQLService(baseUrl: 'http://localhost:8080/graphql')` is instantiated inline in each screen — there is no environment configuration on the frontend side
- **No circular imports:** Dependency direction is strictly: Infrastructure → Application ← Domain; API → Application. Domain has no imports from other layers.
- **Admin authorisation:** Checked inline in `MutationType` resolvers by inspecting `ctx.ctx.authenticatedVoter.exists(_.isAdmin)`; there is no middleware or role-guard abstraction

## Anti-Patterns

### Hardcoded GraphQL URL in every screen

**What happens:** `GraphQLService(baseUrl: 'http://localhost:8080/graphql')` is constructed directly inside `initState()` in `ActiveElectionsScreen`, `_EleicoesAdminSection` in `main.dart`, and other screens.
**Why it's wrong:** Changing the backend URL requires modifying multiple files; the app cannot target staging vs production without a rebuild.
**Do this instead:** Define a single `AppConfig` constant or environment flavor in `frontend/lib/core/services/graphql_service.dart` and pass it at the `MaterialApp` level or via a service locator.

### No Voting Use Case

**What happens:** A `VoteScreen` route exists (`frontend/lib/features/election/presentation/screens/vote_screen.dart`) and a voting button is shown to authenticated users in `ActiveElectionsScreen`, but there is no `vote` GraphQL mutation, no backend use case, and no `votes` table in the schema.
**Why it's wrong:** Core electoral functionality (casting votes) is unimplemented while the UI surface presents it as available.
**Do this instead:** Implement `CastVoteAlg[F]`, `CastVoteUseCase`, `VoteRepository[F]`, `DoobieVoteRepository`, and a `castVote` GraphQL mutation before enabling the `VoteScreen` route.

## Error Handling

**Strategy:** Railway-oriented programming using `EitherT` in domain and application layers; no exceptions thrown in business logic

**Patterns:**
- Domain logic returns `F[Either[DomainError, Result]]`; application use cases propagate this unchanged or wrap via `EitherT`
- GraphQL resolvers pattern-match on `Either` and map to success/error union types (e.g., `CreateElectionPayload = ElectionPayload | ElectionError`)
- Infrastructure errors (DB failures) surface as uncaught `Throwable`; `MutationType` uses `.handleError(_ => ErrorPayload(...))` for UUID parsing failures only
- Frontend services catch `Exception` from `GraphQLService` and propagate; screens display errors via `FutureBuilder` `snapshot.hasError`

## Cross-Cutting Concerns

**Logging:** `log4cats` with SLF4J/Logback backend; `LoggingAspect.around` wraps operations with start/end/duration/error log lines; configured in `backend/src/main/resources/logback.xml`
**Audit logging:** `AuditedLoginUseCase` and `AuditedRegisterVoterUseCase` record `AuditEvent` rows to `audit_log` table via `DoobieAuditLogRepository`; also logs to SLF4J for register events
**Authentication:** Per-request JWT verification in `Main.scala` before context assembly; `MutationType` resolvers perform admin role checks inline
**Database migrations:** Flyway runs `V1–V6__*.sql` scripts at startup from `src/main/resources/db/migration/`

---

*Architecture analysis: 2026-05-21*
