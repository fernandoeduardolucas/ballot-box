# Domain Pitfalls — VotoSeguro Vote-Casting Implementation

**Domain:** Electronic voting system (university project)
**Stack:** Scala 3 + Cats Effect + Doobie + PostgreSQL + Sangria GraphQL + Flutter
**Researched:** 2026-05-21

---

## Critical Pitfalls

Mistakes that cause incorrect vote counts, duplicate votes, or data loss.

---

### Pitfall 1: UNIQUE Constraint Is Necessary But Not Sufficient — Application Layer Must Still Check First

**What goes wrong:**
The UNIQUE constraint on `(voter_id, election_id)` prevents duplicate rows at the database level, but if the application does not check for an existing vote *before* inserting, every duplicate attempt arrives at PostgreSQL as a failed transaction. The constraint catches it correctly, but the error surfaces as an `org.postgresql.util.PSQLException` with `SQLState 23505`. If that exception is not explicitly handled in the Doobie repository, it propagates through `Dispatcher.unsafeToFuture` as an untyped `Future` failure. Sangria then converts it to a raw GraphQL error with the full JDBC exception message — leaking table names, column names, and constraint names to the client.

**Why it happens:**
The existing pattern in `MutationType.scala` uses `.handleError(_ => SomeErrorPayload("..."))` only for UUID parse failures, not for constraint violations. There is no typed `VoteAlreadyCast` error in the domain. The PSQL exception escapes to the GraphQL layer unhandled.

**Consequences:**
- Duplicate vote attempt returns a raw internal error message to the client instead of a friendly "already voted" message.
- Client cannot distinguish "already voted" from "server crashed" — both appear as GraphQL errors.
- Internal schema details are exposed in the error string.

**Prevention:**
1. In `CastVoteRepository.save`, catch `PSQLException` with `getSQLState == "23505"` and translate it to `Left(VoteAlreadyCast)` before returning to the use case.
2. Define `VoteAlreadyCast` as a sealed domain error alongside the vote domain types.
3. The use case can optionally do a pre-check (`findByVoterAndElection`) and return `Left(VoteAlreadyCast)` before attempting the insert — this avoids roundtrip exception handling but is not a substitute for the constraint (race condition window still exists between check and insert).

**Detection (warning signs):**
- GraphQL response contains `"PSQLException"` or `"duplicate key value violates unique constraint"` in the `errors` array.
- Client shows a generic error banner instead of a specific "already voted" message.

**Phase/component:** V7 migration + `CastVoteRepository` + `CastVoteUseCase` + Sangria `MutationType` castVote field.

---

### Pitfall 2: Race Condition Window Between Application-Layer Check and INSERT

**What goes wrong:**
A common approach is: (1) query whether a vote already exists, (2) if not, insert. Under concurrent load two requests from the same voter can both pass step 1 before either completes step 2. The UNIQUE constraint prevents the second INSERT from succeeding, but the first write is duplicated in intent (and the second throws). This is not a theoretical concern — Flutter's `http` package retries on network timeout by default in some configurations, and the confirmation dialog does not disable the VOTAR button during the in-flight request (see current `_VoteButton` implementation which is stateless after confirmation).

**Why it happens:**
The current `_confirmVote` method in `VoteScreen` sets `_voted = true` only on `confirmed == true` from the dialog — before any network call exists. Once the real mutation is wired in, if the mutation is called and the user navigates back and re-enters the screen (state is lost because `_voted` is local widget state), they can vote again until the DB constraint stops them.

**Consequences:**
- Multiple in-flight GraphQL mutations sent by the same client session.
- Backend must handle two simultaneous INSERTs — constraint saves data integrity, but the UX shows an error for what should be a transparent "already voted" case.

**Prevention:**
1. Add a `_submitting` boolean flag in `_VoteScreenState`. Set it to `true` before calling the mutation. Disable the VOTAR button (`enabled: !_submitting && !_voted`). Set to `false` only after the response (success or error) is received.
2. Never derive the "voted" state from local widget state alone after wiring to the backend. On screen mount (or re-entry), query the backend (or pass `hasVoted` as part of `VoteScreenArgs`) so the screen reflects server truth.
3. On the Sangria resolver, rely on the UNIQUE constraint as the final arbiter — return `VoteAlreadyCast` on constraint violation rather than panicking.

**Detection (warning signs):**
- Network tab shows two identical `castVote` mutation requests sent within milliseconds.
- The success banner shows but a second request is still in flight.

**Phase/component:** `VoteScreen` Flutter widget + `CastVoteUseCase` error handling.

---

### Pitfall 3: Election Active Status Checked at Request Time, Not Stored in JWT — Clock Drift and Time Zone Issues

**What goes wrong:**
`ListActiveElectionsUseCase` calls `Sync[F].delay(java.time.Instant.now())` and passes it to `repo.findActive(now)`. The SQL uses `TIMESTAMPTZ` columns (confirmed in V3 migration), which is correct. However, the "is election active?" check for the `castVote` mutation must happen at vote submission time inside the mutation resolver — not be assumed from the fact the voter is on the VoteScreen.

The `ElectionDetailScreen` in Flutter calls `DateTime.now()` (local device time, no timezone conversion) to compute `ended` and `remaining`. If the device clock differs from the server clock by even a few minutes, the Flutter UI will show "VOTAÇÃO ABERTA" while the server rejects the vote as outside the window (or vice versa).

`_InfoSection._progressValue()` and the `ended` / `urgent` flags all use `DateTime.now()` — local time. The `_StatusBar` hardcodes `'Encerra em 2h 45m'` — a stub that does not compute actual remaining time from the election's `endDate`.

**Why it happens:**
- The Flutter screen receives `ElectionItem` with `startDate` and `endDate` as `DateTime` objects parsed from the GraphQL response ISO 8601 string. If `DateTime.parse()` is used without explicitly calling `.toUtc()`, Dart may interpret the string in local time on some platforms.
- The vote-active check has not yet been implemented on the backend, so the timing bug is latent.

**Consequences:**
- Voter presses VOTAR on a closed election and receives an error with no explanation.
- On the flip side, the UI says "ENCERRADA" but the vote would actually be accepted (if election has not truly ended server-side).
- The server must be the authoritative source for "is this election active?" — the client check is display-only.

**Prevention:**
1. In the `castVote` mutation resolver (Sangria), load the election by ID and check `Instant.now().isAfter(election.startDate) && Instant.now().isBefore(election.endDate)` server-side. Return `ElectionNotActive` error if outside the window. Both `startDate` and `endDate` are `TIMESTAMPTZ` so PostgreSQL stores them in UTC — use `Instant` throughout the Scala code, never `LocalDateTime`.
2. In Flutter, always parse dates with `DateTime.parse(isoString).toUtc()` to ensure the `DateTime` is in UTC regardless of device locale. When displaying, convert to local: `utcDate.toLocal()`. Never compare `DateTime.now()` (local) against a `DateTime` that might be in UTC.
3. Use `<=` (not `<`) for `start_date` check and `>=` (not `>`) for `end_date` — a vote submitted at the exact boundary millisecond should be accepted. The existing `findActive` SQL uses `start_date <= $now AND end_date >= $now` which is correct; replicate this boundary semantics in the Scala-side check.

**Detection (warning signs):**
- Votes being rejected with "election not active" errors during the nominal open window.
- `DateTime` objects in Dart are printed without a `Z` suffix (indicating local time, not UTC).

**Phase/component:** `CastVoteUseCase` server-side time check + Flutter `ElectionItem` date parsing + `VoteScreen` status display.

---

### Pitfall 4: candidateId Not Validated as Belonging to the Election

**What goes wrong:**
The `castVote` mutation will accept `(electionId, candidateId)` as arguments. If the server only checks that `candidateId` exists in the `candidates` table but does not verify that `candidates.election_id = electionId`, a client can submit a vote for a candidate from a different election. Because the `votes` table (to be created in V7/V8) stores `(voter_id, election_id, candidate_id)`, the UNIQUE constraint on `(voter_id, election_id)` would still pass, but the `candidate_id` would point to a candidate belonging to a different election — silently corrupting results.

**Why it happens:**
The simplest Doobie query `SELECT id FROM candidates WHERE id = $candidateId` confirms the candidate exists but does not scope it to the election. This pattern appears elsewhere: `QueryType.scala` similarly fetches candidates for an election but does not validate the reverse direction.

**Consequences:**
- Vote counts for an election include votes cast for candidates from other elections.
- `electionResults` query returns inflated counts or zero counts for the correct candidates.
- Cannot be detected without cross-table consistency checks after the fact.

**Prevention:**
Use a scoped lookup: `SELECT id FROM candidates WHERE id = $candidateId AND election_id = $electionId`. If the query returns no row, return `CandidateNotInElection` error. This is a single SQL query — no overhead beyond what the repository already does.

Add a foreign key from `votes.candidate_id` to `candidates.id` in the V7/V8 migration, and additionally consider a CHECK or trigger that `votes.election_id = candidates.election_id` (or enforce it at application level via the scoped lookup).

**Detection (warning signs):**
- `electionResults` shows candidates with zero votes despite confirmed submissions.
- A vote for election A's candidate appears in election B's results.

**Phase/component:** `CastVoteRepository` candidate validation query + V7/V8 migration schema design.

---

### Pitfall 5: Votes Table Migration Number Collision

**What goes wrong:**
`CONCERNS.md` notes the `votes` table is absent from Flyway migrations. The recommended next migration number is V7. However the same document also suggests creating V7 as a seed migration and V8 as the votes table. If both are created in the same branch without coordination, Flyway will fail on the second run with a checksum error if either file is edited after being applied to a local database.

More concretely: if a developer runs the app, creating V7 on their local DB, then edits V7's SQL (to add a column), Flyway will refuse to start with `FlywayException: Validate failed: Migration checksum mismatch`. This is unrecoverable without manual `DELETE FROM flyway_schema_history WHERE version = '7'`.

**Why it happens:**
Flyway checksums every applied migration. Any change after application — even whitespace — breaks the chain. Developers who run the backend locally and iterate on migration SQL are especially vulnerable.

**Consequences:**
- Backend fails to start: `FlywayException` before the server accepts any connection.
- Every developer who applied the broken migration must repair their local DB manually.

**Prevention:**
1. Write the V7 migration SQL completely and correctly before running the backend for the first time with that migration.
2. Never edit a migration file that has been committed and run. If a change is needed, create V8.
3. During development, use `flyway.cleanDisabled=false` and `flyway.clean()` on a local throwaway DB only — never on shared or production databases.
4. Keep the `votes` table creation as a single focused migration (e.g., V7), separate from seed data (V8 if needed).

**Detection (warning signs):**
- Backend logs: `FlywayException: Validate failed`.
- Developers report "backend won't start" after pulling a branch that has migration changes.

**Phase/component:** V7 migration authoring.

---

## Moderate Pitfalls

---

### Pitfall 6: Sangria Admin Check Performed Inside the Resolver, Not at the Field Level

**What goes wrong:**
The existing `createElection` and `addCandidate` resolvers perform the admin check as an imperative `if` block inside the `resolve` function body:

```scala
if (ctx.ctx.authenticatedVoter.isEmpty)
  Future.successful(ElectionErrorPayload("Autenticação necessária."))
else if (!ctx.ctx.authenticatedVoter.exists(_.isAdmin))
  Future.successful(ElectionErrorPayload("Acesso restrito a administradores."))
else { ... actual logic ... }
```

The planned `electionResults` query must follow the same pattern but it is a **Query** field, not a Mutation field. It is easy to forget to add the auth check to query resolvers, since the existing precedent for auth checks is only in mutations. A resolver added to `QueryType` without an admin guard exposes vote counts to any authenticated (or even unauthenticated) caller — violating the "admin-only results in real time" product requirement.

**Why it happens:**
Sangria does not have a built-in field-level authorization middleware in the same way some frameworks do. Without a centralized auth interceptor, each field resolver must remember to check `ctx.ctx.authenticatedVoter`. The query fields (`activeElections`, `allElections`, `electionCandidates`) have no auth check at all — by design for public queries — making the pattern inconsistent.

**Consequences:**
- `electionResults` returns live vote counts to any voter who knows the query, before the election closes.
- Breach of ballot secrecy: if results are visible during voting, voters may be influenced or voters may infer how others voted.

**Prevention:**
1. Add the admin guard to the `electionResults` field resolver in `QueryType` using the same two-condition pattern already established in `MutationType`.
2. Define a reusable helper in `ElectionContext` or as a separate object:
   ```scala
   def requireAdmin[A](ctx: ElectionContext)(body: => Future[A])(fallback: => Future[A]): Future[A] =
     if ctx.authenticatedVoter.exists(_.isAdmin) then body else fallback
   ```
   Centralizing this reduces the risk of forgetting on future fields.
3. Do not rely on the Flutter admin tab being hidden as security — always enforce server-side.

**Detection (warning signs):**
- A non-admin GraphQL query for `electionResults` returns data instead of an error.
- The `authenticatedVoter` field is not referenced anywhere in the `electionResults` resolver.

**Phase/component:** `QueryType.electionResults` field + `ElectionContext` helper.

---

### Pitfall 7: `Dispatcher.unsafeToFuture` Leaks Internal Error Details to GraphQL Clients

**What goes wrong:**
All resolver effects are bridged via `ctx.ctx.dispatcher.unsafeToFuture(...)`. When an unhandled exception occurs inside an `IO` (e.g., a Doobie connection error, a `PSQLException` from a constraint violation, a `NoSuchElementException` from `.get` on `None`), the exception propagates as a failed `Future`. Sangria wraps this in a `GraphQL errors` array entry whose `message` field is `exception.getMessage`. For PostgreSQL exceptions, this message contains the full constraint name, table name, and detail string.

The `castVote` mutation is especially vulnerable because it is the first write path being added and will touch the new UNIQUE constraint.

**Consequences:**
- Internal database structure is exposed to clients in error messages.
- Stack traces may appear in development, where Sangria is configured to include `exceptionHandler`.

**Prevention:**
Wrap the IO in every new resolver with a typed error handler before passing to `unsafeToFuture`:

```scala
ctx.ctx.dispatcher.unsafeToFuture(
  castVoteIO.handleErrorWith {
    case e: PSQLException if e.getSQLState == "23505" =>
      IO.pure(VoteAlreadyCastPayload("Já votou nesta eleição."))
    case _ =>
      IO.pure(VoteErrorPayload("Erro interno. Tente novamente."))
  }
)
```

This is the "Safe modification" pattern already described in `CONCERNS.md` for the fragile resolver bridge — apply it to `castVote` from day one.

**Detection (warning signs):**
- GraphQL response `errors[0].message` contains the word `PSQLException`, `duplicate key`, or a Java class name.
- `CONCERNS.md` explicitly flags this for all existing resolvers.

**Phase/component:** `MutationType.castVote` resolver + any new `QueryType` fields.

---

### Pitfall 8: Flutter Vote Screen Loses "Already Voted" State on Navigation Pop/Push

**What goes wrong:**
The current `_voted` flag is widget-local state in `_VoteScreenState`. When the voter navigates away (back to `ElectionDetailScreen`) and then returns to `VoteScreen`, a new `_VoteScreenState` is created with `_voted = false`. The VOTAR button is re-enabled. The voter can press it again. The only protection at that point is the backend constraint.

When the real mutation is wired in, the backend will correctly reject the duplicate with `VoteAlreadyCast`. But the UX will show an error ("Erro interno" or similar) instead of gracefully showing the already-voted confirmation banner.

**Why it happens:**
Flutter widget state does not survive navigation stack operations unless explicitly preserved (e.g., via `AutomaticKeepAliveClientMixin`, route-level state, or passing `hasVoted` as a route argument).

**Consequences:**
- Confusing UX: voter sees an error on a legitimate "try again" navigation that any non-malicious user might do.
- Voter may interpret the error as a failed vote and contact support, believing their vote was not cast.

**Prevention:**
1. Pass `hasVoted` as part of `VoteScreenArgs` (alongside `election` and `candidates`). This value must come from the backend — query it when building `ElectionDetailScreen` (e.g., a `hasVoted(electionId)` query that returns a boolean, admin-exempt from result data).
2. Alternatively, on receiving a `VoteAlreadyCast` error from the mutation, transition to the same success banner state (`_voted = true`) with a message "O seu voto já se encontra registado." This is the minimum-effort approach.
3. Do not disable navigation from VoteScreen while vote is in flight — just ensure the state is server-aware on re-entry.

**Detection (warning signs):**
- Navigation back and forward to VoteScreen shows the VOTAR button re-enabled after a successful vote.
- The backend rejects the second attempt with `VoteAlreadyCast` but the error banner appears instead of the confirmation banner.

**Phase/component:** `VoteScreen` state management + optional `hasVoted` GraphQL query.

---

### Pitfall 9: `VoteScreenArgs` Route Arguments Are Not Type-Safe — Null Cast Crashes

**What goes wrong:**
`PROJECT.md` specifies `VoteScreen` receives `VoteScreenArgs(election, candidates)` via `ModalRoute.settings.arguments`. The current `VoteScreen` ignores `arguments` entirely. When the wiring is added, the typical Flutter pattern is:

```dart
final args = ModalRoute.of(context)!.settings.arguments as VoteScreenArgs;
```

If `VoteScreen` is navigated to without arguments (e.g., during development, or if a future code path calls `pushNamed('/elections/vote')` without arguments), this cast throws a `TypeError` at runtime, crashing the screen with an uncaught exception that shows the red error screen.

**Why it happens:**
Flutter's routing system passes arguments as `Object?` — the type cast is unchecked at compile time. This is a known Flutter routing pain point.

**Consequences:**
- Runtime crash with opaque error on any navigation that omits the arguments object.
- Hard to discover in testing because the happy path always provides arguments.

**Prevention:**
1. Add a null check and type guard in `VoteScreen.build` or `initState`:
   ```dart
   final args = ModalRoute.of(context)?.settings.arguments;
   if (args is! VoteScreenArgs) {
     // Navigate back or show an error — do not crash.
     WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
     return const SizedBox.shrink();
   }
   ```
2. Define `VoteScreenArgs` as a typed class (not a `Map`) to make the cast explicit.
3. The `ElectionDetailScreen` currently passes only `widget.election` as arguments (line 67–68) — it must be updated to pass `VoteScreenArgs(election: widget.election, candidates: snapshot.data!)` at the same time as `VoteScreen` is wired up.

**Detection (warning signs):**
- Red error screen on VoteScreen during development navigation.
- `_CastError` or `TypeError` in Flutter debug console.

**Phase/component:** `ElectionDetailScreen` navigation call + `VoteScreen` argument extraction.

---

### Pitfall 10: `audit_log` Entry for `castVote` Uses Voter's Civil ID in Plain Text

**What goes wrong:**
`AuditedLoginUseCase` records `AuditEvent("LOGIN", Some(civilIdRaw), ...)` — the voter's civil ID is stored as `actor` in the `audit_log` table. When `AuditedCastVoteUseCase` is created following the same pattern, it will record `civilIdRaw` (or `voterId`) in the audit log alongside the `election_id`. If `candidate_id` is also included in the audit entry, the audit log becomes a direct mapping from voter identity to vote choice — breaking ballot secrecy.

**Why it happens:**
The audit log pattern is designed for authentication events where linking identity to action is the purpose. Applying the same pattern unchanged to vote casting inadvertently creates a voter-to-candidate linkage.

**Consequences:**
- Ballot secrecy violated: anyone with read access to `audit_log` can determine how each voter voted.
- The UI states "O seu voto é secreto" — this claim would be false.

**Prevention:**
The `AuditedCastVoteUseCase` audit event must record that a vote was cast but must NOT record which candidate was chosen. The event should be:

```
AuditEvent("VOTE_CAST", actor = Some(voterId.toString), ip, success = true, reason = Some(electionId.toString))
```

Where `reason` contains only the `electionId` (confirming participation in which election), not the `candidateId`. The candidate choice must never appear in any log, audit table, or error message.

**Detection (warning signs):**
- `audit_log` contains a column or JSON field mapping voter identity to candidate choice.
- The `AuditEvent` data class is passed `candidateId` as part of its `reason` or `actor` fields.

**Phase/component:** `AuditedCastVoteUseCase` design + `AuditEvent` field selection.

---

## Minor Pitfalls

---

### Pitfall 11: `electionResults` Query Returns Candidate Names Alongside Counts — Leaks Candidate Existence Before Election Starts

**What goes wrong:**
If `electionResults` returns a list of `{ candidateName, voteCount }` and is called before the election ends, it reveals the full candidate list regardless of the election status. While this is admin-only, it is worth noting as a schema design concern.

**Prevention:**
Return `{ candidateId, candidateName, voteCount }` — scope the query to elections that have started (or the admin explicitly knows the candidate list anyway). Not a security issue for admin-only access, but good practice for consistency.

**Phase/component:** `electionResults` GraphQL schema + query resolver.

---

### Pitfall 12: `ExecutionContext.global` Shared With Sangria During Vote Submission

**What goes wrong:**
`CONCERNS.md` flags that `given ExecutionContext = ExecutionContext.global` in `Main.scala` (line 65) shares the global fork-join pool with all Sangria executions. Under concurrent vote submission load, this can cause thread pool starvation where Cats Effect IO computations (database writes) are blocked waiting for threads occupied by Sangria's internal scheduling.

**Prevention:**
Replace with a dedicated `ExecutionContext` from a bounded thread pool before the voting feature goes live. The minimum fix is `ExecutionContext.fromExecutorService(Executors.newFixedThreadPool(N))` wrapped in a `Resource` for cleanup. The ideal fix (noted in `CONCERNS.md`) is to eliminate the Sangria `Future` bridge entirely and use `Dispatcher` consistently — already partially done via `unsafeToFuture`.

**Phase/component:** `Main.scala` wiring — pre-production hardening.

---

### Pitfall 13: Flutter `GraphQLService` Has No Timeout — Vote Mutation Hangs Indefinitely

**What goes wrong:**
The `GraphQLService` (used by all screens) constructs HTTP requests without an explicit timeout. If the backend is slow or unreachable during vote submission, the `castVote` mutation future never resolves. The `_submitting` flag (if added per Pitfall 2 prevention) stays `true` forever. The VOTAR button is permanently disabled with no feedback.

**Prevention:**
Add a timeout to the HTTP client or the specific mutation call:
```dart
.timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('...'))
```
Handle the `TimeoutException` in the mutation caller and set `_submitting = false` with an error message so the voter can retry.

**Phase/component:** `GraphQLService` + `VoteScreen` mutation call site.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|----------------|------------|
| V7/V8 migration authoring | Flyway checksum corruption if SQL edited post-apply (Pitfall 5) | Write migration completely before first run; never edit after commit |
| `CastVoteRepository.save` | PSQL 23505 leaks as raw exception (Pitfall 1) | Catch `PSQLException` and return `Left(VoteAlreadyCast)` |
| `castVote` Sangria resolver | Unhandled IO errors leak internal details (Pitfall 7) | Wrap in `.handleErrorWith` before `unsafeToFuture` |
| `CastVoteUseCase` | Time check absent — votes accepted outside election window (Pitfall 3) | Load election, check `Instant.now()` is within `[startDate, endDate]` |
| `CastVoteUseCase` | candidateId not scoped to election (Pitfall 4) | Use `SELECT id FROM candidates WHERE id=$cid AND election_id=$eid` |
| `AuditedCastVoteUseCase` | Audit log maps voter to candidate choice (Pitfall 10) | Record only `(VOTE_CAST, voterId, electionId)` — omit candidateId |
| `electionResults` QueryType field | No admin guard on query field (Pitfall 6) | Add `requireAdmin` check mirroring MutationType pattern |
| `VoteScreen` Flutter wiring | Double-tap / re-entry re-enables VOTAR (Pitfall 2, 8) | Add `_submitting` flag; derive voted state from server response |
| `VoteScreen` args extraction | Null cast crash if arguments absent (Pitfall 9) | Type-guard args; handle null gracefully |
| `ElectionDetailScreen` navigation | Currently passes only `ElectionItem`, not candidates (Pitfall 9) | Update to pass `VoteScreenArgs(election, candidates)` |
| `VoteScreen` date display | Hardcoded "Encerra em 2h 45m" + local clock vs UTC mismatch (Pitfall 3) | Parse dates as UTC; compute remaining from server-provided `endDate` |

---

## Sources

- Direct inspection of `MutationType.scala`, `QueryType.scala`, `Main.scala`, `DoobieElectionRepository.scala`, `VoteScreen.dart`, `ElectionDetailScreen.dart`, `AuditedLoginUseCase.scala`, `AuditAspect.scala`
- `CONCERNS.md` — codebase audit 2026-05-21: fragile resolver bridge, missing votes table, admin trust-from-JWT, ExecutionContext.global
- `PROJECT.md` — active requirements: UNIQUE constraint as concurrency guarantee, AuditedCastVoteUseCase pattern, VoteScreenArgs routing
- V3 migration (`TIMESTAMPTZ` confirmed), V4 migration (candidates schema confirmed)
- PostgreSQL documentation: SQLState 23505 for unique_violation
- Sangria documentation: resolver error propagation via Future bridge
- Flutter routing documentation: `ModalRoute.settings.arguments` type-cast behavior
