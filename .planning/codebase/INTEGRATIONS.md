# External Integrations

**Analysis Date:** 2026-05-21

## APIs & External Services

**GraphQL API (self-hosted):**
- The sole communication channel between frontend and backend
- Endpoint: `POST /graphql` (default: `http://localhost:8080/graphql`)
- Schema entry points:
  - Queries: `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/QueryType.scala`
  - Mutations: `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/MutationType.scala`
  - Schema object types: `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/schemas/`
- Client: `frontend/lib/core/services/graphql_service.dart` — plain HTTP POST using `package:http`; no dedicated GraphQL client library

**Google Fonts (CDN):**
- Used by: `frontend/lib/main.dart`, `frontend/pubspec.yaml`
- SDK: `google_fonts` 6.2.1
- Fonts loaded: IBM Plex Sans, IBM Plex Mono, Instrument Serif, Atkinson Hyperlegible
- Requires internet access at runtime in web builds; fonts are bundled in native builds

## Data Storage

**Databases:**
- PostgreSQL 16
  - Connection env var: `DB_URL` (default `jdbc:postgresql://localhost:5432/elections`)
  - Credentials env vars: `DB_USER`, `DB_PASSWORD` (both default `elections`)
  - Database name: `elections`
  - Client: Doobie 1.0.0-RC8 with `org.postgresql.Driver` via `Transactor.fromDriverManager`
  - Repository implementations:
    - `backend/src/main/scala/pt/ipp/estg/elections/identity/infrastructure/DoobieVoterRepository.scala`
    - `backend/src/main/scala/pt/ipp/estg/elections/identity/infrastructure/DoobieAuditLogRepository.scala`
    - `backend/src/main/scala/pt/ipp/estg/elections/election/infrastructure/DoobieElectionRepository.scala`
    - `backend/src/main/scala/pt/ipp/estg/elections/election/infrastructure/DoobieCandidateRepository.scala`

**Schema Migrations:**
- Tool: Flyway 9.22.3
- Location: `backend/src/main/resources/db/migration/`
- Applied automatically on backend startup before the HTTP server starts
- Migration files:
  - `V1__Create_voters_table.sql` — `voters` table (id UUID PK, civil_id unique, password_hash)
  - `V2__Create_audit_log_table.sql` — `audit_log` table
  - `V3__Create_elections_table.sql` — `elections` table (id UUID PK, title, start_date, end_date, created_at; constraint end > start)
  - `V4__Create_candidates_table.sql` — `candidates` table
  - `V5__Add_nut3_region_to_voters.sql` — adds `nut3_region` column to voters
  - `V6__Add_is_admin_to_voters.sql` — adds `is_admin` boolean to voters

**File Storage:**
- Not used. No file upload or object storage integration.

**Caching:**
- None. No Redis, Memcached, or in-memory cache layer.

## Authentication & Identity

**Auth Provider:**
- Custom, self-hosted — no third-party auth provider (no Auth0, Firebase Auth, Supabase, etc.)
- Implementation:
  - Password hashing: BCrypt via `jBCrypt` 0.4
    - `backend/src/main/scala/pt/ipp/estg/elections/identity/infrastructure/BcryptPasswordHasher.scala`
    - `backend/src/main/scala/pt/ipp/estg/elections/identity/infrastructure/BcryptPasswordVerifier.scala`
  - Token generation: JWT (HS256) via `jwt-scala/jwt-circe` 9.4.6
    - `backend/src/main/scala/pt/ipp/estg/elections/identity/infrastructure/JwtTokenGenerator.scala`
    - `backend/src/main/scala/pt/ipp/estg/elections/identity/infrastructure/JwtTokenVerifier.scala`
  - JWT payload contains: `sub` (voter UUID), `civilId`, `nut3Region`, `isAdmin`
  - JWT secret: `JWT_SECRET` env var (default `change-me-in-production`)
  - JWT expiry: `JWT_EXPIRATION_SECONDS` (default 86400 = 24 hours)
- Token transport: `Authorization: Bearer <token>` header extracted in `Main.scala`
- Frontend token storage: in-memory singleton `AuthStore` at `frontend/lib/core/auth/auth_store.dart` — **not persisted across page reloads**
- GraphQL mutations `registerVoter` and `loginVoter` are unauthenticated; `createElection` and `addCandidate` require an authenticated admin token

## Monitoring & Observability

**Error Tracking:**
- None. No Sentry, Datadog, Rollbar, or equivalent integration.

**Logs:**
- Backend: SLF4J + Logback Classic 1.5.18 via log4cats-slf4j 2.7.0
  - Named loggers used: `"audit.identity.register"` (see `AuditedRegisterVoterUseCase` in `Main.scala`)
  - Logback config file not present in repo — falls back to Logback's default (INFO to stdout)
- Frontend: No structured logging; errors surface via Flutter exception handling and `FutureBuilder` error states

**Audit Log (database-level):**
- Login events are persisted to `audit_log` table via `DoobieAuditLogRepository`
- `backend/src/main/scala/pt/ipp/estg/elections/aop/AuditEvent.scala` — event model (eventType, civilId, ip, success, reason)
- Client IP extracted from `X-Forwarded-For` / `X-Real-Ip` headers or falls back to `"unknown"`
- Audit log streaming endpoint configured at `/audit/stream` (WebSocket path in `application.conf`) — server-side wiring not confirmed in current codebase

## CI/CD & Deployment

**Hosting:**
- Not configured. No Dockerfile, Kubernetes manifests, or cloud provider config files are present.
- Docker Compose (`docker-compose.yml`) is for local development only (PostgreSQL + pgAdmin).

**CI Pipeline:**
- None detected. No `.github/workflows/`, `.gitlab-ci.yml`, or equivalent.

## Environment Configuration

**Required environment variables (production):**
- `JWT_SECRET` — must be changed from default `change-me-in-production`
- `DB_URL` — JDBC connection string to PostgreSQL
- `DB_USER` — database user
- `DB_PASSWORD` — database password
- `APP_HOST` — bind host (optional, defaults to `0.0.0.0`)
- `APP_PORT` — bind port (optional, defaults to `8080`)

**Secrets location:**
- No `.env` file present in repository. All secrets are passed via OS environment variables.
- Docker Compose uses hardcoded development credentials (postgres/elections, pgAdmin admin/admin) — for local dev only.

**Frontend backend URL:**
- Hardcoded as `'http://localhost:8080/graphql'` in multiple files:
  - `frontend/lib/main.dart` (admin section `_EleicoesAdminSectionState`)
  - Individual feature service files in `frontend/lib/features/`
- No build-time environment injection; changing target environment requires code edits.

## Webhooks & Callbacks

**Incoming:**
- None detected.

**Outgoing:**
- None detected. No calls to external HTTP endpoints from backend code.

## Postman Collection

**API documentation:**
- `docs/postman/ballot-box-graphql.postman_collection.json` — Postman collection documenting the GraphQL API

---

*Integration audit: 2026-05-21*
