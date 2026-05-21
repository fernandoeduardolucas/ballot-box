# Research Summary - VotoSeguro Vote-Casting Module

**Project:** VotoSeguro - ballot-box
**Synthesized:** 2026-05-21
**Research files:** STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md
**Confidence (overall):** HIGH - all four research files derive from direct codebase inspection and verified library knowledge.

---

## Executive Summary

VotoSeguro requires a vote-casting module extending the existing Scala 3 / Cats Effect / Doobie / Sangria / Flutter codebase. The module is a straightforward bounded context addition - no new architectural patterns are needed. The correct concurrency guarantee is a PostgreSQL UNIQUE constraint on (voter_id, election_id), not application-level locking. The constraint must be paired with PSQLException 23505 interception in DoobieVoteRepository, which translates the database error to the typed domain value AlreadyVoted before it can escape to the GraphQL layer. Every other pattern already exists in the codebase and must be followed exactly.

The two highest-risk correctness concerns are: (1) ballot secrecy in the audit log - AuditedCastVoteUseCase must record the voter identity and the election but must never log the candidateId, because doing so creates a permanent voter-to-candidate mapping in the audit_log table that directly contradicts the ballot secrecy claim in the UI; and (2) the electionResults query in QueryType must carry the same admin guard as mutation fields - all existing query fields are public so the check must be added explicitly.

On the Flutter side, VoteScreen requires three backend-driven fixes: a _submitting flag to prevent duplicate in-flight mutations, a VoteScreenArgs route argument class carrying both the election and its candidate list, and server-derived voted state. All UTC date parsing in ElectionItem must call .toUtc() to prevent device-clock timezone drift.

---

## Key Findings

### From STACK.md - Technology Decisions

| Decision | Rationale | Confidence |
|----------|-----------|------------|
| UNIQUE constraint (voter_id, election_id) as concurrency guarantee | DB-level serializable; survives restarts; enforced for direct SQL. SELECT FOR UPDATE requires a pre-existing row; advisory locks require hash-based keys with collision risk; check-then-insert is a TOCTOU race. | HIGH |
| Intercept PSQLException 23505 in DoobieVoteRepository with .recoverWith on F | Post-transact interception matches existing repository style. | HIGH |
| MonadCancelThrow[F] in repository, Sync[F] in use case | Identical to all existing repos and use cases. Sync[F] needed for Instant.now(). | HIGH |
| Do NOT wrap .transact(xa) in IO.blocking | Doobie Transactor already manages thread shifting. | HIGH |

**Critical version notes:**
- Doobie 1.0.0-RC8: .transact, .attempt, .recoverWith, ConnectionIO are stable.
- Cats Effect 3.5.7: MonadCancelThrow, Sync, FlatMap are core stable APIs.
- PostgreSQL JDBC 42.x via doobie-postgres: PSQLException.getSQLState() returning 23505 is SQL-standard behaviour.

### From FEATURES.md - Feature Scope

**Table stakes (must ship):**
- castVote GraphQL mutation with JWT guard (voter identity from token, not args)
- Election-is-active validation in use case using Sync[F].delay(Instant.now())
- Candidate-belongs-to-election validation (pure check: candidate.electionId == ElectionId(electionId))
- One-vote enforcement: application-level hasVoted pre-check + DB UNIQUE constraint backstop
- VoteError sealed ADT: AlreadyVoted, ElectionNotActive, ElectionNotFound, VoterNotFound, CandidateNotInElection
- CastVotePayload union type (success: VotePayload; failure: VoteErrorPayload)
- V7 Flyway migration: votes table with UNIQUE(voter_id, election_id) and two indexes
- VoteRepository[F], DoobieVoteRepository, CastVoteAlg[F], CastVoteUseCase, AuditedCastVoteUseCase
- ElectionContext extended with castVoteUseCase and getVoteResultsUseCase
- VoteScreenArgs(election, candidates) replacing the current hardcoded candidate list
- VoteService.castVote in Flutter; post-vote UI driven by CastVoteResult from server
- electionResults admin-only query with admin guard in QueryType
- Admin results tab in Flutter consuming real vote counts

**Differentiators (v1 non-blocking):**
- Live election time-remaining display computed from ElectionItem.endDate
- Proactive already-voted state on VoteScreen re-entry
- Percentage breakdown in results (pure client-side calculation)

**Anti-features (do not build):**
- Cryptographic ballot anonymisation - out of scope per PROJECT.md
- WebSocket push for live results - v2 feature
- Voter-visible results during voting - electionResults must be admin-only
- Vote modification or retraction - UNIQUE constraint enforces immutability at DB level
- IP blacklisting or rate limiting - UNIQUE constraint is sufficient for TP2

### From ARCHITECTURE.md - Component Design

**Module structure:** New vote/ bounded context under pt.ipp.estg.elections/, mirroring identity/ and election/ exactly.

| Component | Responsibility |
|-----------|----------------|
| Vote (domain entity) | Aggregate root: VoteId, VoterId, CandidateId, ElectionId, castedAt |
| VoteRepository[F] | Domain port: save, hasVoted, countByCandidate |
| VoteError (sealed ADT) | All distinguishable failure cases for the mutation resolver |
| CastVoteLogic (pure object) | EitherT pipeline with callbacks - no infrastructure imports |
| CastVoteUseCase | Orchestrates callbacks from real repo calls; calls voteRepo.save |
| DoobieVoteRepository | Implements VoteRepository; catches PSQLException 23505 here only |
| AuditedCastVoteUseCase | Decorator via flatTap; records event WITHOUT candidateId |
| VoteSchema.scala | All vote-related Sangria types in one file (union type pattern) |

**Key patterns to follow:**
- Callback pattern in CastVoteLogic (mirrors VoterRegistrationLogic) - domain has zero infrastructure imports.
- EitherT pipeline in CastVoteUseCase (mirrors AddCandidateUseCase).
- flatTap in AuditedCastVoteUseCase (mirrors AuditedLoginUseCase) - does not alter result.
- UnionType in VoteSchema.scala for CastVotePayload (mirrors CreateElectionPayload).
- LEFT JOIN votes ... GROUP BY candidate_id in countByCandidate ensures zero-vote candidates appear.

**Build order (dependency graph):**
1. V7 migration SQL
2. Domain: VoteError -> Vote -> VoteRepository -> CastVoteLogic
3. Application: CastVoteAlg -> GetVoteResultsAlg -> CastVoteUseCase -> GetVoteResultsUseCase
4. Infrastructure: DoobieVoteRepository
5. AOP: AuditedCastVoteUseCase
6. API: VoteSchema -> ElectionContext (extend) -> MutationType (add castVote) -> QueryType (add electionResults with admin guard)
7. Wiring: Main.scala

### From PITFALLS.md - Risk Register

**Critical pitfalls (data integrity / correctness):**

| Pitfall | Prevention |
|---------|------------|
| PSQLException 23505 escapes to GraphQL layer as raw JDBC error | Catch in DoobieVoteRepository with .recoverWith; translate to Left(AlreadyVoted) |
| Race condition between hasVoted check and INSERT | DB UNIQUE constraint is the authoritative backstop; always handle 23505 in repository |
| candidateId not validated against specific election | Scoped lookup: SELECT id FROM candidates WHERE id=cid AND election_id=eid; return CandidateNotInElection if no row |
| Audit log records candidateId - ballot secrecy violated | AuditedCastVoteUseCase records (VOTE_CAST, voterId, electionId) only; candidateId is NEVER logged |
| electionResults query in QueryType missing admin guard | Add authenticatedVoter.exists(_.isAdmin) check; existing query fields are public and provide no template |
| Flyway V7 migration edited after first apply | Write migration completely before first backend run |

**Moderate pitfalls (UX / edge cases):**

| Pitfall | Prevention |
|---------|------------|
| Flutter double-submit (no _submitting flag) | Add _submitting boolean; disable VOTAR button while mutation is in flight |
| Flutter _voted state lost on screen re-entry | Pass server-derived hasVoted in VoteScreenArgs or treat AlreadyVoted response as success state |
| UTC vs local clock mismatch in Flutter date parsing | Always call .toUtc() on ISO 8601 strings; server is authoritative for active-window check |
| VoteScreenArgs null cast crashes VoteScreen | Type-guard args extraction; handle missing args gracefully |
| Unhandled IO exceptions leak internal details via unsafeToFuture | Wrap resolver IO in .handleErrorWith before unsafeToFuture |

---

## Implications for Roadmap

Research across all four files points to a clean 3-phase implementation. Each phase is independently verifiable and unblocks the next.

### Phase 1 - Schema and Domain Core

**Rationale:** Everything depends on the database schema and domain types. The Flyway migration must be authored in full before any backend run to avoid checksum corruption.

**Delivers:** V7__Create_votes_table.sql with UNIQUE constraint and indexes; VoteError sealed ADT; Vote domain entity and value objects; VoteRepository[F] domain port trait; CastVoteLogic pure object.

**Features from FEATURES.md:** One-vote-per-voter schema guarantee (table stakes)
**Pitfalls to avoid:** Flyway checksum corruption (Pitfall 5) - write migration completely before first run
**Research flag:** Well-documented patterns. No research phase needed.

### Phase 2 - Backend Vertical Slice

**Rationale:** Build the full castVote path from infrastructure to GraphQL in one slice. The AOP decorator must be wired before the mutation is exposed. The admin guard on electionResults must be added at the same time as the query field - not retrofitted later.

**Delivers:** DoobieVoteRepository (PSQLException 23505 caught here); CastVoteAlg[F] + CastVoteUseCase (candidateId scoped to election); GetVoteResultsAlg[F] + GetVoteResultsUseCase; AuditedCastVoteUseCase (logs electionId only - candidateId excluded); VoteSchema.scala + MutationType.castVote + QueryType.electionResults (admin guard required); ElectionContext extended; Main.scala wired.

**Features from FEATURES.md:** All backend table stakes (castVote mutation, electionResults admin query)
**Pitfalls to avoid:** Pitfall 1 (23505 interception); Pitfall 10 (ballot secrecy in audit log); Pitfall 6 (admin guard on QueryType); Pitfall 7 (IO error leak via unsafeToFuture)
**Research flag:** Well-documented patterns. No research phase needed.

### Phase 3 - Flutter Wiring

**Rationale:** Flutter work depends on a working backend endpoint. Build order: VoteScreenArgs -> route change -> screen reads real data -> mutation call -> UI state from server.

**Delivers:** VoteScreenArgs(election, candidates) typed class; ElectionDetailScreen route push updated; VoteScreen reads candidates from args; _submitting flag in _VoteScreenState; VoteService.castVote + CastVoteResult sealed class; post-vote UI state from server; UTC date parsing with .toUtc(); admin results tab.

**Features from FEATURES.md:** All Flutter-facing table stakes; server-derived voted state
**Pitfalls to avoid:** Pitfall 2 (double-submit); Pitfall 9 (VoteScreenArgs null cast); Pitfall 3 (UTC vs local clock); Pitfall 8 (state on re-entry)
**Research flag:** Well-documented patterns. No research phase needed.

---

## Research Flags

| Phase | Research Needed? | Reason |
|-------|-----------------|--------|
| Phase 1 (Schema + Domain) | No | Flyway migration conventions, Doobie value objects, and sealed ADTs all have direct codebase precedents |
| Phase 2 (Backend Vertical Slice) | No | PSQLException interception, EitherT pipeline, AOP decorator, and Sangria union types all have existing implementations |
| Phase 3 (Flutter Wiring) | No | VoteService, route args, and widget state patterns all follow existing Flutter service and screen conventions |

No phase requires --research-phase during planning.

---

## Confidence Assessment

| Area | Confidence | Basis |
|------|------------|-------|
| Stack (Doobie / Cats Effect / PostgreSQL) | HIGH | Direct library version verification from build.sbt; PSQLException 23505 is SQL-standard; all APIs are stable RC8 |
| Features | HIGH | Derived from direct codebase analysis and PROJECT.md requirements; no speculation |
| Architecture | HIGH | All component designs are extensions of existing patterns; no new patterns introduced |
| Pitfalls | HIGH | Each pitfall is grounded in observed codebase code paths or PostgreSQL/Flutter documented behaviour |

**Gaps to address during planning:**

1. CandidateRepository.findByElection - ARCHITECTURE.md uses this method as a callback in CastVoteUseCase. Verify whether it exists before Phase 2; add it if absent.

2. Server-derived voted state strategy - two options: pass hasVoted: Boolean in VoteScreenArgs (requires backend query when building ElectionDetailScreen) or treat AlreadyVoted mutation response as silent success state (simpler). Pick one before Phase 3.

3. IP threading in AuditedCastVoteUseCase - can be n/a (simplest) or threaded through CastVoteAlg.execute signature. Confirm before Phase 2.

---

## Critical Implementation Rules (Non-Negotiable)

1. **UNIQUE constraint is the concurrency guarantee - not application locks.** The DB constraint on (voter_id, election_id) is the authoritative safety net. Application-level hasVoted pre-check improves UX but is NOT a substitute for the constraint.

2. **PSQLException 23505 MUST be caught in DoobieVoteRepository and translated to AlreadyVoted.** It must not escape to the use case, the GraphQL resolver, or the client. This is the single correct interception point per Clean Architecture boundaries.

3. **AuditedCastVoteUseCase MUST NOT log candidateId.** Record only (VOTE_CAST, voterId, electionId). Including the candidate choice in the audit log violates ballot secrecy and directly contradicts the UI claim that votes are secret.

4. **candidateId MUST be validated against the specific election.** A candidate existence check alone is insufficient. Use a scoped query or pure domain check to prevent cross-election vote injection.

5. **electionResults query in QueryType MUST have an admin guard.** All existing query fields are public. The admin check must be added explicitly, mirroring the MutationType pattern.

6. **Flutter VoteScreen MUST have a _submitting flag.** Without it, double-tap or re-navigation allows multiple in-flight mutations. The DB constraint stops data corruption but the UX shows an error instead of graceful handling.

7. **Flutter must parse all ISO 8601 date strings with .toUtc().** Device local time must never be compared directly against server UTC timestamps.

---

## Aggregated Sources

- backend/src/main/scala/pt/ipp/estg/elections/ - all existing bounded contexts (direct inspection)
- backend/src/main/resources/db/migration/V1-V6 - Flyway migration conventions
- lib/ Flutter source - vote_screen.dart, election_detail_screen.dart, election_service.dart
- build.sbt - Doobie 1.0.0-RC8, Cats Effect 3.5.7, PostgreSQL JDBC 42.x
- PROJECT.md - active requirements and explicit out-of-scope declarations
- CONCERNS.md - codebase audit: fragile resolver bridge, missing votes table, ExecutionContext.global
- PostgreSQL documentation: SQLSTATE class 23 (integrity constraint violation), subclass 23505
- Sangria documentation: resolver error propagation via Future bridge
- Flutter routing documentation: ModalRoute.settings.arguments type-cast behaviour
