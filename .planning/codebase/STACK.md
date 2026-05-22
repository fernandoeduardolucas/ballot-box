# Technology Stack

**Analysis Date:** 2026-05-21

## Languages

**Primary (Backend):**
- Scala 3.6.4 - All backend application code under `backend/src/main/scala/`

**Primary (Frontend):**
- Dart (SDK `>=3.4.0 <4.0.0`) - All frontend code under `frontend/lib/`

**Secondary:**
- SQL - PostgreSQL DDL/DML migration scripts under `backend/src/main/resources/db/migration/`

## Runtime

**Backend:**
- JVM (no explicit version pinned in build; SBT 1.10.11 drives the build — see `backend/project/build.properties`)
- Entry point: `backend/src/main/scala/pt/ipp/estg/elections/Main.scala` (extends `IOApp.Simple`)

**Frontend:**
- Flutter web/mobile runtime (Dart SDK)
- Development web target: `flutter run -d web-server --web-port 3000`

**Package Manager:**
- Backend: SBT 1.10.11 — `backend/project/build.properties`, `backend/build.sbt`
- Frontend: `pub` (Flutter) — `frontend/pubspec.yaml`
- Lockfile: `frontend/pubspec.lock` (present for Flutter); SBT uses `project/` for lockdown

## Frameworks

**Backend Core:**
- Cats Effect 3.5.7 — async IO runtime, all effectful code wrapped in `F[_]: Sync/MonadCancelThrow`
- Cats Core 2.10.0 — functional abstractions (`Either`, `Option`, typeclasses)
- http4s Ember Server 0.23.34 — HTTP server (`EmberServerBuilder` in `Main.scala`)
- http4s DSL 0.23.34 — route definition (`HttpRoutes.of[IO]`)
- http4s Circe 0.23.34 — JSON request/response decoding
- Sangria 3.4.1 — GraphQL schema/execution engine (`backend/src/main/scala/pt/ipp/estg/elections/api/graphql/`)
- Sangria-Circe 1.3.2 — Sangria ↔ Circe JSON bridge
- Doobie Core 1.0.0-RC8 — functional JDBC wrapper for PostgreSQL queries
- Doobie Postgres 1.0.0-RC8 — PostgreSQL-specific Doobie extensions (UUID, etc.)
- Flyway Core 9.22.3 — database migrations on startup (`runMigrations` in `Main.scala`)
- PureConfig Core 0.17.7 — typesafe config loading from `application.conf`
- PureConfig Generic Scala3 0.17.7 — Scala 3 derivation for PureConfig
- jwt-scala / jwt-circe 9.4.6 — JWT generation and verification (`JwtTokenGenerator`, `JwtTokenVerifier`)
- jBCrypt 0.4 — BCrypt password hashing (`BcryptPasswordHasher`, `BcryptPasswordVerifier`)
- Logback Classic 1.5.18 — SLF4J logging backend
- log4cats-slf4j 2.7.0 — Cats Effect-native structured logging facade

**Backend Testing:**
- MUnit 1.1.0 — test runner with Scala 3 support
- munit-cats-effect 2.0.0 — IO-based test suites (`CatsEffectSuite`)

**Frontend Core:**
- Flutter (Material Design 3 / `useMaterial3: true`) — widget framework, routing
- `http` 1.2.2 — HTTP client used by `GraphQLService` for all backend calls
- `web_socket_channel` 3.0.1 — WebSocket support (declared; audit stream path configured server-side at `/audit/stream`)
- `google_fonts` 6.2.1 — IBM Plex Sans, IBM Plex Mono, Instrument Serif, Atkinson Hyperlegible fonts

**Frontend Dev:**
- `flutter_lints` 5.0.0 — Dart lint rules

**Build/Dev:**
- Docker Compose (local PostgreSQL + pgAdmin) — `docker-compose.yml`
- PowerShell dev launcher — `start-dev.ps1`

## Key Dependencies

**Critical (Backend):**
- `cats-effect` 3.5.7 — entire async execution model depends on this; all use cases are `F[_]`-polymorphic
- `doobie-postgres` 1.0.0-RC8 — all database access; `Transactor.fromDriverManager` with `org.postgresql.Driver`
- `sangria` 3.4.1 — the entire API layer is GraphQL; no REST routes exist
- `flyway-core` 9.22.3 — schema migrations run before server starts; missing DB = startup failure
- `jwt-circe` 9.4.6 — authentication token lifecycle

**Critical (Frontend):**
- `http` 1.2.2 — all API communication goes through `GraphQLService` (`frontend/lib/core/services/graphql_service.dart`)

**Infrastructure:**
- `pureconfig-core` 0.17.7 — config must be valid HOCON or server will not start (`loadOrThrow`)
- `logback-classic` 1.5.18 — runtime logging; config expected at `backend/src/main/resources/logback.xml` (not yet present — falls back to default)

## Configuration

**Backend Environment:**
- Config file: `backend/src/main/resources/application.conf` (HOCON format via Typesafe Config)
- All values have defaults; all can be overridden by environment variables:
  - `APP_HOST` (default `0.0.0.0`)
  - `APP_PORT` (default `8080`)
  - `DB_URL` (default `jdbc:postgresql://localhost:5432/elections`)
  - `DB_USER` (default `elections`)
  - `DB_PASSWORD` (default `elections`)
  - `JWT_SECRET` (default `change-me-in-production` — **must be changed in production**)
  - `JWT_EXPIRATION_SECONDS` (default `86400`)
- Config model: `backend/src/main/scala/pt/ipp/estg/elections/config/AppConfig.scala`

**Frontend Environment:**
- Backend URL is hardcoded in several places as `http://localhost:8080/graphql`
  - `frontend/lib/main.dart` (line 525): `GraphQLService(baseUrl: 'http://localhost:8080/graphql')`
  - Individual screens instantiate `GraphQLService` with the same hardcoded URL
- No environment variable injection mechanism exists in the Flutter app

**Build:**
- Backend: `backend/build.sbt` (SBT multi-project build, single `root` project)
- Frontend: `frontend/pubspec.yaml`
- Compiler flags: `-deprecation`, `-feature`, `-unchecked` (see `build.sbt`)

## Platform Requirements

**Development:**
- Docker and Docker Compose (for PostgreSQL 16 and pgAdmin4)
- SBT 1.10.11
- Scala 3.6.4 (managed by SBT)
- Flutter SDK (Dart `>=3.4.0`)
- PostgreSQL client driver bundled via SBT (`doobie-postgres` includes the JDBC driver)
- PowerShell (for `start-dev.ps1` launcher on Windows)

**Production:**
- Any JVM-compatible host for the backend fat JAR
- Static web hosting or mobile app stores for the Flutter frontend
- PostgreSQL 16 database
- Environment variables for all secrets (especially `JWT_SECRET`)

---

*Stack analysis: 2026-05-21*
