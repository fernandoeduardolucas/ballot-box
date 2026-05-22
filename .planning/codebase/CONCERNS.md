# Codebase Concerns

**Analysis Date:** 2026-05-21

---

## Tech Debt

**Vote submission is entirely a UI stub:**
- Issue: `VoteScreen` (`frontend/lib/features/election/presentation/screens/vote_screen.dart`) uses a hardcoded in-memory `_candidates` list with fictional names, parties, and avatar URLs from `pravatar.cc`. The "VOTAR" button only sets `_voted = true` locally — no GraphQL mutation is sent, no vote is persisted, no backend `votes` table is written to.
- Files: `frontend/lib/features/election/presentation/screens/vote_screen.dart`
- Impact: Core electoral function does not work. Any user can press "Votar" and believe they voted, but nothing is recorded.
- Fix approach: Add a `castVote` GraphQL mutation to the backend (new `VoteUseCase`), write to the `votes` table (schema already exists in `backend/src/main/resources/db/001_schema.sql`), and wire the Flutter screen to that mutation.

**Results and Audit UI tabs are placeholder stubs:**
- Issue: `HomePage` in `frontend/lib/main.dart` renders `_PlaceholderSection` widgets for both "Resultados" and "Auditoria" tabs, with hardcoded messages such as "O registo de auditoria está em desenvolvimento."
- Files: `frontend/lib/main.dart` (lines ~180–185)
- Impact: Election results cannot be viewed; audit log is inaccessible from the UI.
- Fix approach: Implement `electionResults` GraphQL query (vote counts per candidate per election) and an `auditLog` query returning paginated `audit_log` entries.

**Two conflicting database schemas:**
- Issue: `backend/src/main/resources/db/001_schema.sql` is a legacy hand-written schema (elections/candidates/voters/votes/audit_log) that diverges significantly from the Flyway migrations (V1–V6). The Flyway schema has different column names (`start_date`/`end_date` vs `starts_at`/`ends_at`), a different `audit_log` structure, additional fields (`nut3_region`, `is_admin`, `party`, `photo_url`, `number`), and no `votes` table in the migrations at all. `002_seed.sql` references the legacy schema columns (`starts_at`).
- Files: `backend/src/main/resources/db/001_schema.sql`, `backend/src/main/resources/db/002_seed.sql`, `backend/src/main/resources/db/migration/V1__Create_voters_table.sql` through `V6__Add_is_admin_to_voters.sql`
- Impact: If `001_schema.sql` is ever run it conflicts with Flyway migrations. The seed file `002_seed.sql` uses `starts_at`/`ends_at` columns that do not exist in the Flyway-managed schema, so running it will fail with a column-not-found error.
- Fix approach: Delete or archive `001_schema.sql` and `002_seed.sql`. Create a `V7__Seed_initial_data.sql` Flyway migration with corrected column names (`start_date`/`end_date`). Add a `V8__Create_votes_table.sql` migration to support the actual voting use case.

**`ExecutionContext.global` used throughout Sangria execution:**
- Issue: `Main.scala` line 65 declares `given ExecutionContext = ExecutionContext.global`, which is shared with all Sangria `Executor.execute` calls. The global pool is a fixed-size fork-join pool sized to available processors; it will bottleneck under any real concurrent load, and mixing it with the Cats Effect IO runtime risks thread pool starvation.
- Files: `backend/src/main/scala/pt/ipp/estg/elections/Main.scala` (line 65)
- Impact: Performance degradation under load; potential thread starvation during peak requests.
- Fix approach: Replace with a dedicated unbounded or bounded `ExecutionContext` obtained via `Resource`, or use `cats.effect.std.Dispatcher` consistently (already available in scope) to avoid the `Future`-based executor path entirely.

**JWT secret falls back to a predictable literal:**
- Issue: `application.conf` sets `secret = "change-me-in-production"` as the default when `JWT_SECRET` env var is absent. Nothing at startup validates that the secret has been changed.
- Files: `backend/src/main/resources/application.conf` (line 36), `backend/src/main/scala/pt/ipp/estg/elections/identity/infrastructure/JwtTokenGenerator.scala`
- Impact: In any deployment where `JWT_SECRET` is not explicitly set, all tokens are signed with a publicly known key. An attacker can forge admin tokens.
- Fix approach: Add a startup check in `Main.scala` that throws if `config.security.jwt.secret == "change-me-in-production"`, or enforce a minimum secret entropy. Document the requirement explicitly.

**Backend URL hardcoded to `localhost:8080` in every Flutter screen:**
- Issue: Every screen and service in the frontend constructs `GraphQLService(baseUrl: 'http://localhost:8080/graphql')` inline. There is no configuration layer — changing the backend address requires editing at least 6 separate files.
- Files: `frontend/lib/features/identity/presentation/screens/login_screen.dart` (line 27, line 234), `frontend/lib/features/election/presentation/screens/active_elections_screen.dart` (line 17), `frontend/lib/features/election/presentation/screens/election_detail_screen.dart` (line 17), `frontend/lib/main.dart` (line 525), `frontend/lib/features/election/presentation/screens/add_candidate_screen.dart` (line 28)
- Impact: Cannot deploy to staging or production without modifying source. HTTP (not HTTPS) is used, which is insecure for a production electoral system.
- Fix approach: Extract `baseUrl` into a single `AppConfig` Dart class (or a `--dart-define` build flag), instantiate `GraphQLService` once and inject it via constructor, or use a dependency injection solution.

---

## Known Bugs

**`electionCandidates` query silently swallows UUID parse errors:**
- Symptoms: If an invalid UUID is passed for `electionId`, `QueryType.scala` line 57 calls `.handleError(_ => List.empty)` returning an empty list instead of an error. The client sees "no candidates" rather than an error message.
- Files: `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/QueryType.scala` (line 57)
- Trigger: Pass a malformed UUID string as `electionId` to `electionCandidates`.
- Workaround: None — clients cannot distinguish between "election has no candidates" and "invalid election ID".

**`findByCivilId` silently drops voters with unknown NUT3 codes:**
- Symptoms: `DoobieVoterRepository.findByCivilId` calls `Nut3Region.fromCode(regionCode).map { ... }` — if the stored `nut3_region` value in the database does not match any enum code, the row is silently converted to `None`, and `LoginVoterUseCase` returns `VoterNotFound`. A voter who registered with a valid code that is later removed from the enum will be permanently locked out.
- Files: `backend/src/main/scala/pt/ipp/estg/elections/identity/infrastructure/DoobieVoterRepository.scala` (lines 35–38)
- Trigger: Delete a `Nut3Region` enum case while voters with that code exist in the database.
- Workaround: None without code change.

**`002_seed.sql` is incompatible with the Flyway schema:**
- Symptoms: `INSERT INTO elections ... (starts_at, ends_at)` — columns are `start_date` and `end_date` in the Flyway schema. Running this seed file will produce a PostgreSQL column-not-found error.
- Files: `backend/src/main/resources/db/002_seed.sql`
- Trigger: Attempt to run `002_seed.sql` against a Flyway-migrated database.
- Workaround: Do not run `002_seed.sql`. Use manual inserts with correct column names.

---

## Security Considerations

**No rate limiting on login or registration mutations:**
- Risk: The `loginVoter` and `registerVoter` GraphQL mutations have no rate limiting, CAPTCHA, or account lockout mechanism. This enables unlimited brute-force password attempts and mass voter registration with fake identities.
- Files: `backend/src/main/scala/pt/ipp/estg/elections/Main.scala`, `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/MutationType.scala`
- Current mitigation: None.
- Recommendations: Add http4s middleware for rate limiting per IP (e.g., a token bucket via `cats.effect.Ref`), or a reverse-proxy rule (nginx `limit_req`).

**Admin privilege is trust-based from the JWT payload — no re-verification on each request:**
- Risk: `MutationType.scala` checks `ctx.ctx.authenticatedVoter.exists(_.isAdmin)` where `authenticatedVoter` is decoded from the JWT token in `Main.scala`. If the `is_admin` column is revoked in the database after a token is issued, the token remains valid for its full `expiration-seconds` window (default 86400 s = 24 h).
- Files: `backend/src/main/scala/pt/ipp/estg/elections/Main.scala` (line 126), `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/MutationType.scala` (lines 78–82, 111–113)
- Current mitigation: None — admin flag is solely from the token payload.
- Recommendations: Either shorten token expiration for admin accounts, add a token revocation list, or re-fetch the voter record from the database on each privileged request to verify `is_admin` is still true.

**`X-Forwarded-For` header is trusted without validation:**
- Risk: `Main.scala` reads the client IP from `X-Forwarded-For` (line 49–52) without checking whether the request came through a trusted proxy. Any client can spoof this header to log a false IP in the audit log.
- Files: `backend/src/main/scala/pt/ipp/estg/elections/Main.scala` (lines 47–52)
- Current mitigation: None.
- Recommendations: Only trust `X-Forwarded-For` if the connection originates from a known proxy IP; otherwise fall back to the direct connection address.

**Frontend auth token stored in a plain in-memory singleton — no logout on tab close:**
- Risk: `AuthStore` (`frontend/lib/core/auth/auth_store.dart`) stores the JWT token in a plain Dart field. On Flutter Web, if the page is refreshed the token is lost (forces re-login), but for native builds the process memory persists for the app lifetime. There is no token expiry check on the client side before sending requests.
- Files: `frontend/lib/core/auth/auth_store.dart`
- Current mitigation: None.
- Recommendations: For web, persist to `window.sessionStorage` (not localStorage) so the token is cleared on tab close. Add client-side expiry checks by decoding the JWT `exp` claim before sending requests.

**`photoUrl` field for candidates is not validated:**
- Risk: Any URL string is accepted as `photoUrl` when adding a candidate. No scheme validation is performed server-side or client-side (beyond a `startsWith('http')` preview check in the Flutter UI). A `javascript:` URI or a data URI could be injected and rendered by `Image.network`.
- Files: `backend/src/main/scala/pt/ipp/estg/elections/election/domain/AddCandidateLogic.scala`, `frontend/lib/features/election/presentation/screens/add_candidate_screen.dart`
- Current mitigation: Flutter's `Image.network` only loads HTTP/HTTPS URLs, providing partial protection.
- Recommendations: Validate that `photoUrl` is a well-formed `https://` URL on the backend before persisting.

**Wildcard CORS policy in production configuration:**
- Risk: `Main.scala` configures `CORS.policy.withAllowOriginAll.withAllowMethodsAll.withAllowHeadersAll`, allowing any origin to make credentialed cross-site requests. For a production electoral platform this is inappropriate.
- Files: `backend/src/main/scala/pt/ipp/estg/elections/Main.scala` (lines 149–153)
- Current mitigation: None.
- Recommendations: Restrict `allowOrigin` to the known frontend domain in production.

---

## Performance Bottlenecks

**No database connection pool — using `DriverManager` transactor:**
- Problem: `Main.scala` constructs a `Transactor.fromDriverManager`, which opens a new JDBC connection for every transaction (one per request). Under any non-trivial concurrency this saturates PostgreSQL's connection limit.
- Files: `backend/src/main/scala/pt/ipp/estg/elections/Main.scala` (lines 73–78)
- Cause: `Transactor.fromDriverManager` is explicitly documented by Doobie as unsuitable for production.
- Improvement path: Replace with `Transactor.fromHikariConfig` using the `doobie-hikari` module with a bounded pool (e.g. 10 connections), configured via `HikariConfig`.

**No pagination on `allElections` and `electionCandidates` queries:**
- Problem: Both `allElections` and `electionCandidates` return unbounded `List` results. With thousands of elections or candidates the response can become arbitrarily large.
- Files: `backend/src/main/scala/pt/ipp/estg/elections/election/infrastructure/DoobieElectionRepository.scala` (line 32), `backend/src/main/scala/pt/ipp/estg/elections/election/application/ListElectionCandidatesUseCase.scala`
- Cause: No `LIMIT`/`OFFSET` or cursor-based pagination added.
- Improvement path: Add `limit` and `offset` GraphQL arguments; apply `LIMIT $limit OFFSET $offset` in the SQL queries.

---

## Fragile Areas

**`Dispatcher.unsafeToFuture` bridges IO to Sangria Future — error propagation is lossy:**
- Files: `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/QueryType.scala`, `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/MutationType.scala`
- Why fragile: All resolver effects are bridged via `ctx.ctx.dispatcher.unsafeToFuture(...)`. Unhandled exceptions inside an `IO` that reach this bridge are wrapped as failed `Future`s. Sangria catches these and converts them to GraphQL errors, but the error message bubbles as a raw `Exception.getMessage` string — potentially leaking internal stack traces or database error messages to clients.
- Safe modification: Wrap all resolver `IO` calls in `.handleErrorWith(e => IO.pure(ErrorPayload(e.getMessage)))` before passing to `unsafeToFuture`, so all error paths return typed GraphQL union members.
- Test coverage: No test covers the error response shape for resolver exceptions.

**`Voter.validateFormat` accepts any string of length >= 8 as a civil ID:**
- Files: `backend/src/main/scala/pt/ipp/estg/elections/identity/domain/Voter.scala` (line 18)
- Why fragile: The only validation is `civilId.length >= 8`. There is no format check (e.g., alphanumeric, specific pattern). Any 8-character string registers as a valid civil ID.
- Safe modification: Add a regex or structural validation appropriate for the intended civil ID format (e.g., Portuguese Cartão de Cidadão format) in `Voter.validateFormat`.
- Test coverage: `ElectionServiceSuite.scala` tests the 8-character length rule but not format validity.

**`AuthStore` is a global mutable singleton without change notification:**
- Files: `frontend/lib/core/auth/auth_store.dart`
- Why fragile: Widgets reading `AuthStore.instance.isAuthenticated` or `AuthStore.instance.isAdmin` do so at build time with no reactive listener. After `clearToken()` or `setSession()`, only widgets that call `setState` manually will re-render. Several screens (e.g., `active_elections_screen.dart` line 32–35) call `setState` on logout, but widgets that embed inline references to `AuthStore.instance.isAdmin` mid-build (e.g., `main.dart` line 284) may display stale state until manually refreshed.
- Safe modification: Wrap `AuthStore` in a `ValueNotifier<AuthState>` and use `ListenableBuilder` or `ValueListenableBuilder` in consuming widgets.
- Test coverage: No frontend tests exist.

---

## Scaling Limits

**Single-instance in-memory WebSocket audit path (configured but not implemented):**
- Current capacity: The `application.conf` declares `websocket.audit.path = "/audit/stream"`, but no WebSocket route is registered in `Main.scala`. The `web_socket_channel` dependency is present in `pubspec.yaml` but unused.
- Limit: When implemented, any in-memory broadcast approach will not work across multiple server instances.
- Scaling path: Implement the WebSocket route backed by a `cats.effect.std.Topic[IO, AuditEvent]` for single-instance use; use a Redis pub/sub or similar for multi-instance deployment.

---

## Missing Critical Features

**No `votes` table in the Flyway migration chain:**
- Problem: The `votes` table exists only in the legacy `001_schema.sql` hand-written schema but is absent from all Flyway migrations (V1–V6). There is no backend `CastVoteUseCase`, no `castVote` GraphQL mutation, and no `VoteRepository`.
- Blocks: The entire voting flow — the core purpose of the system.

**No election results query:**
- Problem: No GraphQL query exists to retrieve vote counts or results for an election. The "Resultados" tab in `main.dart` is a placeholder.
- Blocks: Post-election result announcement; auditing vote totals.

**No token revocation / session invalidation:**
- Problem: Issued JWTs are valid until expiry (default 24 h) with no server-side invalidation. There is no logout endpoint, no token denylist.
- Blocks: Secure logout; immediate privilege revocation.

**No double-vote prevention enforcement:**
- Problem: Even if a `castVote` endpoint were added, there is no backend uniqueness constraint preventing a voter from voting multiple times (the schema in `001_schema.sql` has `PRIMARY KEY (election_id, voter_hash)` but this table does not exist in the Flyway migrations).
- Blocks: Vote integrity.

---

## Test Coverage Gaps

**Only voter registration domain logic is tested:**
- What's not tested: Login, all election use cases (create, list, add candidate), all GraphQL resolvers, JWT token generation/verification, Doobie repository implementations, AuditedLoginUseCase, AuditAspect, CORS/middleware config.
- Files: `backend/src/test/scala/pt/ipp/estg/elections/ElectionServiceSuite.scala` (4 tests, all in `RegisterVoterUseCase`)
- Risk: Regressions in auth, election management, or audit paths go undetected.
- Priority: High

**No Flutter widget or integration tests:**
- What's not tested: All screens, `AuthStore` state transitions, `GraphQLService` HTTP handling, all service layer parsing logic.
- Files: `frontend/` — no test files beyond the default flutter_test scaffolding.
- Risk: UI regressions and API contract breaks are only caught at runtime.
- Priority: High

**`ElectionServiceSuite` does not pass `nut3Code` argument despite updated signatures:**
- What's not tested: Registration with an explicit NUT3 region. The test calls `execute("12345678", "password123")` with 2 arguments, but `RegisterVoterUseCase.execute` requires 3 (`civilIdRaw`, `rawPassword`, `nut3Code`). This means either the test file is stale relative to the current signature, or the test does not compile — masking the NUT3 validation path entirely.
- Files: `backend/src/test/scala/pt/ipp/estg/elections/ElectionServiceSuite.scala` (lines 21, 24, 27, 30)
- Risk: NUT3 validation is untested; compilation failure would break CI silently if the test target is not run.
- Priority: High

---

*Concerns audit: 2026-05-21*
