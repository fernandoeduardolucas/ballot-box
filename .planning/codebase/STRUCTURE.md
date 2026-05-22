# Codebase Structure

**Analysis Date:** 2026-05-21

## Directory Layout

```
ballot-box/
├── backend/                        # Scala 3 / Cats Effect / http4s backend
│   ├── build.sbt                   # SBT build definition
│   ├── project/
│   │   └── build.properties        # SBT version (1.10.11)
│   └── src/
│       ├── main/
│       │   ├── resources/
│       │   │   ├── application.conf            # HOCON config (http, db, jwt, websocket)
│       │   │   ├── logback.xml                 # SLF4J/Logback logging config
│       │   │   └── db/
│       │   │       ├── 001_schema.sql          # Manual schema reference (non-Flyway)
│       │   │       ├── 002_seed.sql            # Manual seed reference (non-Flyway)
│       │   │       └── migration/              # Flyway versioned migrations
│       │   │           ├── V1__Create_voters_table.sql
│       │   │           ├── V2__Create_audit_log_table.sql
│       │   │           ├── V3__Create_elections_table.sql
│       │   │           ├── V4__Create_candidates_table.sql
│       │   │           ├── V5__Add_nut3_region_to_voters.sql
│       │   │           └── V6__Add_is_admin_to_voters.sql
│       │   └── scala/pt/ipp/estg/elections/
│       │       ├── Main.scala                  # Application entry point; DI wiring
│       │       ├── aop/                        # Decorator / cross-cutting concerns
│       │       │   ├── AuditEvent.scala
│       │       │   ├── AuditLogAlg.scala
│       │       │   ├── AuditAspect.scala       # AuditedRegisterVoterUseCase
│       │       │   ├── AuditedLoginUseCase.scala
│       │       │   └── LoggingAspect.scala     # LoggingAspect + LoggedRegisterVoterUseCase
│       │       ├── api/
│       │       │   └── graphql/
│       │       │       ├── ElectionContext.scala   # Sangria per-request context
│       │       │       ├── QueryType.scala         # GraphQL query fields
│       │       │       ├── MutationType.scala      # GraphQL mutation fields
│       │       │       └── schemas/
│       │       │           ├── ElectionSchema.scala   # Election/Candidate Sangria types
│       │       │           └── IdentitySchema.scala   # Voter/Login/Register Sangria types
│       │       ├── config/
│       │       │   └── AppConfig.scala             # PureConfig typed config
│       │       ├── election/                        # Election bounded context
│       │       │   ├── application/
│       │       │   │   ├── AddCandidateAlg.scala
│       │       │   │   ├── AddCandidateUseCase.scala
│       │       │   │   ├── CreateElectionAlg.scala
│       │       │   │   ├── CreateElectionUseCase.scala
│       │       │   │   ├── ListActiveElectionsAlg.scala
│       │       │   │   ├── ListActiveElectionsUseCase.scala
│       │       │   │   ├── ListAllElectionsAlg.scala
│       │       │   │   ├── ListAllElectionsUseCase.scala
│       │       │   │   ├── ListElectionCandidatesAlg.scala
│       │       │   │   └── ListElectionCandidatesUseCase.scala
│       │       │   ├── domain/
│       │       │   │   ├── AddCandidateLogic.scala
│       │       │   │   ├── Candidate.scala
│       │       │   │   ├── CandidateError.scala
│       │       │   │   ├── CandidateRepository.scala
│       │       │   │   ├── CreateElectionLogic.scala
│       │       │   │   ├── Election.scala
│       │       │   │   ├── ElectionError.scala
│       │       │   │   └── ElectionRepository.scala
│       │       │   └── infrastructure/
│       │       │       ├── DoobieCandidateRepository.scala
│       │       │       └── DoobieElectionRepository.scala
│       │       └── identity/                    # Identity bounded context
│       │           ├── application/
│       │           │   ├── LoginVoterAlg.scala
│       │           │   ├── LoginVoterUseCase.scala
│       │           │   ├── PasswordHasher.scala
│       │           │   ├── PasswordVerifier.scala
│       │           │   ├── RegisterVoterAlg.scala
│       │           │   ├── RegisterVoterUseCase.scala
│       │           │   ├── TokenGenerator.scala
│       │           │   └── TokenVerifier.scala
│       │           ├── domain/
│       │           │   ├── AuthToken.scala
│       │           │   ├── AuthenticatedVoter.scala
│       │           │   ├── LoginError.scala
│       │           │   ├── Nut3Region.scala
│       │           │   ├── RegistrationError.scala
│       │           │   ├── Voter.scala
│       │           │   ├── VoterLoginLogic.scala
│       │           │   ├── VoterRegistrationLogic.scala
│       │           │   └── VoterRepository.scala
│       │           └── infrastructure/
│       │               ├── BcryptPasswordHasher.scala
│       │               ├── BcryptPasswordVerifier.scala
│       │               ├── DoobieAuditLogRepository.scala
│       │               ├── DoobieVoterRepository.scala
│       │               ├── JwtTokenGenerator.scala
│       │               └── JwtTokenVerifier.scala
│       └── test/
│           └── scala/pt/ipp/estg/elections/
│               └── ElectionServiceSuite.scala
├── frontend/                       # Flutter app (web + mobile)
│   ├── lib/
│   │   ├── main.dart               # App entry, MaterialApp routing, admin HomePage
│   │   ├── core/
│   │   │   ├── auth/
│   │   │   │   └── auth_store.dart         # In-memory singleton JWT store
│   │   │   ├── services/
│   │   │   │   └── graphql_service.dart    # HTTP GraphQL client
│   │   │   └── theme/
│   │   │       └── app_colors.dart         # Design system color tokens
│   │   └── features/
│   │       ├── election/
│   │       │   ├── data/
│   │       │   │   ├── election_service.dart   # Election/Candidate GraphQL queries
│   │       │   │   └── candidate_service.dart  # Candidate GraphQL mutations
│   │       │   └── presentation/
│   │       │       └── screens/
│   │       │           ├── active_elections_screen.dart  # Voter home — list active elections
│   │       │           ├── election_detail_screen.dart   # View candidates for an election
│   │       │           ├── create_election_screen.dart   # Admin — create election
│   │       │           ├── add_candidate_screen.dart     # Admin — add candidate to election
│   │       │           └── vote_screen.dart              # Voter — cast vote (UI stub)
│   │       └── identity/
│   │           ├── data/
│   │           │   └── auth_service.dart       # Login + Register GraphQL mutations
│   │           └── presentation/
│   │               └── screens/
│   │                   └── login_screen.dart   # Login + Register UI
├── docs/                           # Project documentation
├── docker-compose.yml              # PostgreSQL 16 + pgAdmin services
├── start-dev.ps1                   # PowerShell dev startup script
└── README.md
```

## Directory Purposes

**`backend/src/main/scala/.../elections/`:**
- Purpose: All Scala source code, following Clean Architecture vertical slices by bounded context
- Contains: 4 top-level modules — `aop/`, `api/`, `config/`, plus bounded contexts `election/` and `identity/`
- Key files: `Main.scala` (wiring), `api/graphql/ElectionContext.scala` (request context)

**`backend/src/main/scala/.../elections/{election,identity}/domain/`:**
- Purpose: Pure domain models, repository interfaces, and business logic — zero external dependencies
- Contains: Entities, value objects (`AnyVal` wrappers), `sealed trait` error ADTs, pure logic companion objects, repository trait definitions
- Key files: `VoterRegistrationLogic.scala`, `VoterLoginLogic.scala`, `CreateElectionLogic.scala`, `AddCandidateLogic.scala`

**`backend/src/main/scala/.../elections/{election,identity}/application/`:**
- Purpose: Use-case orchestration; port traits (`*Alg`) for use cases and secondary ports (`PasswordHasher`, `TokenGenerator`, etc.)
- Contains: One `*Alg.scala` (trait) and one `*UseCase.scala` (implementation) per use case
- Key files: `RegisterVoterUseCase.scala`, `LoginVoterUseCase.scala`, `CreateElectionUseCase.scala`, `AddCandidateUseCase.scala`

**`backend/src/main/scala/.../elections/{election,identity}/infrastructure/`:**
- Purpose: Concrete implementations of domain repository traits and application port traits
- Contains: `Doobie*Repository` classes, `Bcrypt*`, `Jwt*` implementations
- Key files: `DoobieVoterRepository.scala`, `JwtTokenGenerator.scala`, `JwtTokenVerifier.scala`

**`backend/src/main/scala/.../elections/aop/`:**
- Purpose: Aspect-oriented decorators that wrap use-case Alg traits with cross-cutting behaviour
- Contains: Audit and logging decorator classes + `AuditLogAlg[F]` trait + `AuditEvent` model

**`backend/src/main/scala/.../elections/api/graphql/`:**
- Purpose: Sangria GraphQL schema — field resolvers and type definitions
- Contains: `QueryType`, `MutationType`, `ElectionContext`, `schemas/`

**`backend/src/main/resources/db/migration/`:**
- Purpose: Flyway versioned SQL migrations, applied automatically at startup
- Contains: `V1` through `V6` migration scripts
- Generated: No. Committed: Yes.

**`frontend/lib/core/`:**
- Purpose: App-wide shared infrastructure — HTTP client, auth state, design tokens
- Contains: `auth_store.dart` (singleton session), `graphql_service.dart` (HTTP client), `app_colors.dart` (color palette)

**`frontend/lib/features/{election,identity}/data/`:**
- Purpose: Data layer for each feature — contains service classes that call `GraphQLService` and parse typed results
- Contains: `ElectionService`, `CandidateService`, `AuthService` plus their return type sealed classes

**`frontend/lib/features/{election,identity}/presentation/screens/`:**
- Purpose: Flutter `StatefulWidget` / `StatelessWidget` screens; one file per screen
- Contains: Full screen widget trees; FutureBuilder-based async data loading; navigation calls

## Key File Locations

**Entry Points:**
- `backend/src/main/scala/pt/ipp/estg/elections/Main.scala`: Backend DI wiring + server start
- `frontend/lib/main.dart`: Flutter app root, `MaterialApp` with route table

**Configuration:**
- `backend/src/main/resources/application.conf`: HOCON config for HTTP, DB, JWT, WebSocket paths
- `docker-compose.yml`: PostgreSQL 16 service definition

**Core Logic:**
- `backend/src/main/scala/pt/ipp/estg/elections/identity/domain/VoterRegistrationLogic.scala`: Voter registration business rules
- `backend/src/main/scala/pt/ipp/estg/elections/identity/domain/VoterLoginLogic.scala`: Login business rules
- `backend/src/main/scala/pt/ipp/estg/elections/election/domain/CreateElectionLogic.scala`: Election creation rules
- `backend/src/main/scala/pt/ipp/estg/elections/election/domain/AddCandidateLogic.scala`: Candidate addition rules
- `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/ElectionContext.scala`: GraphQL request context

**Database:**
- `backend/src/main/resources/db/migration/V1__Create_voters_table.sql`: voters schema
- `backend/src/main/resources/db/migration/V2__Create_audit_log_table.sql`: audit_log schema
- `backend/src/main/resources/db/migration/V3__Create_elections_table.sql`: elections schema
- `backend/src/main/resources/db/migration/V4__Create_candidates_table.sql`: candidates schema

**Testing:**
- `backend/src/test/scala/pt/ipp/estg/elections/ElectionServiceSuite.scala`: Only test file

## Naming Conventions

**Scala Backend — Files:**
- `*Alg.scala`: Use-case or secondary-port trait (e.g., `RegisterVoterAlg.scala`, `PasswordHasher.scala`)
- `*UseCase.scala`: Concrete implementation of an `*Alg` trait (e.g., `RegisterVoterUseCase.scala`)
- `*Logic.scala`: Pure domain logic companion object (e.g., `VoterRegistrationLogic.scala`)
- `*Repository.scala`: Repository trait definition (e.g., `VoterRepository.scala`)
- `Doobie*Repository.scala`: Doobie infrastructure implementation (e.g., `DoobieVoterRepository.scala`)
- `*Error.scala`: Sealed trait error ADT (e.g., `RegistrationError.scala`, `ElectionError.scala`)
- `*Schema.scala`: Sangria GraphQL type definitions (e.g., `ElectionSchema.scala`)

**Scala Backend — Identifiers:**
- Traits: PascalCase, descriptive noun or verb phrase (`RegisterVoterAlg`, `ElectionRepository`)
- Case classes: PascalCase (`Voter`, `Election`, `AuthToken`)
- Value objects: PascalCase wrapping `AnyVal` (`ElectionId`, `CivilId`, `PasswordHash`)
- Companion objects (logic): PascalCase noun + `Logic` suffix (`VoterRegistrationLogic`)
- Decorators: Prefixed by concern: `Audited*`, `Logged*`
- Error objects: Descriptive PascalCase (`CivilIdAlreadyExists`, `TitleTooShort`)
- Package: `pt.ipp.estg.election` (note: singular `election`, not `elections`)

**Dart Frontend — Files:**
- `*_screen.dart`: A full Flutter screen widget (e.g., `login_screen.dart`)
- `*_service.dart`: A data-layer service class (e.g., `election_service.dart`, `auth_service.dart`)
- `*_store.dart`: Singleton state container (e.g., `auth_store.dart`)
- `app_*.dart`: App-wide shared resource (e.g., `app_colors.dart`)
- All filenames use `snake_case`

**Dart Frontend — Identifiers:**
- Classes: PascalCase (`ElectionService`, `AuthStore`, `LoginResult`)
- Sealed result classes: `*Result` base + `*Success`/`*Failure` subtypes
- Private widget classes: `_` prefix PascalCase (`_ElectionsHeader`, `_NavChip`)
- Fields/variables: camelCase (`_token`, `_isAdmin`, `baseUrl`)

**SQL Migrations:**
- Format: `V{N}__{Description}.sql` (Flyway standard, e.g., `V3__Create_elections_table.sql`)
- Table names: `snake_case` plural (e.g., `voters`, `audit_log`, `elections`, `candidates`)
- Column names: `snake_case` (e.g., `civil_id`, `password_hash`, `start_date`)

## Where to Add New Code

**New Bounded Context (e.g., `voting`):**
1. Create `backend/src/main/scala/pt/ipp/estg/elections/voting/domain/` — entities, repository trait, error ADT, pure logic object
2. Create `backend/src/main/scala/pt/ipp/estg/elections/voting/application/` — `*Alg.scala` trait + `*UseCase.scala`
3. Create `backend/src/main/scala/pt/ipp/estg/elections/voting/infrastructure/` — `Doobie*Repository.scala`
4. Add new field to `ElectionContext` (`api/graphql/ElectionContext.scala`)
5. Wire in `Main.scala`
6. Add GraphQL field to `QueryType` or `MutationType`; add schema types to a new `schemas/VotingSchema.scala`

**New Use Case within existing context:**
1. Add `*Alg.scala` trait in the appropriate `application/` directory
2. Add `*UseCase.scala` implementing the Alg in the same directory
3. Extend `ElectionContext` with the new Alg
4. Wire the new use case in `Main.scala`
5. Add the resolver field in `QueryType.scala` or `MutationType.scala`

**New Database Table:**
- Create `backend/src/main/resources/db/migration/V{N+1}__{Description}.sql`
- Next migration number after current highest (`V6`) is `V7`

**New Frontend Screen:**
- Create `frontend/lib/features/{feature}/presentation/screens/{name}_screen.dart`
- Register the route in the `routes` map in `frontend/lib/main.dart`
- If the screen needs data: create or extend a service in `frontend/lib/features/{feature}/data/{name}_service.dart`

**New Frontend Feature Module:**
- Create `frontend/lib/features/{feature}/data/` for services
- Create `frontend/lib/features/{feature}/presentation/screens/` for screens
- Follow existing pattern: service receives a `GraphQLService` instance; returns sealed result types

**New AOP Decorator:**
- Create in `backend/src/main/scala/pt/ipp/estg/elections/aop/`
- Implement the target `*Alg[F]` trait; accept the wrapped delegate as constructor parameter
- Wire the decorator chain in `Main.scala` before passing to `ElectionContext`

**Shared frontend utilities:**
- Color tokens: `frontend/lib/core/theme/app_colors.dart`
- HTTP client config: `frontend/lib/core/services/graphql_service.dart`
- Auth session: `frontend/lib/core/auth/auth_store.dart`

## Special Directories

**`backend/src/main/resources/db/migration/`:**
- Purpose: Flyway versioned migration scripts applied automatically at server startup
- Generated: No
- Committed: Yes

**`backend/target/`:**
- Purpose: SBT compiled output and caches
- Generated: Yes
- Committed: No (in .gitignore)

**`frontend/build/`:**
- Purpose: Flutter build artefacts
- Generated: Yes
- Committed: No

**`frontend/.dart_tool/`:**
- Purpose: Dart toolchain metadata
- Generated: Yes
- Committed: No (package_config.json only partially committed)

**`.planning/codebase/`:**
- Purpose: GSD codebase map documents consumed by `/gsd:plan-phase` and `/gsd:execute-phase`
- Generated: By GSD mapper agent
- Committed: Yes

---

*Structure analysis: 2026-05-21*
