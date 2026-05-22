# Roadmap: VotoSeguro — Vote-Casting Module

**Project:** VotoSeguro — ballot-box
**Milestone:** Vote-Casting Feature (Brownfield Addition)
**Created:** 2026-05-21
**Granularity:** Standard (3 phases — focused feature addition)
**Coverage:** 14/14 v1 requirements mapped

---

## Phases

- [x] **Phase 1: Schema & Domain Core** - Establish the data foundation and pure business rules for vote-casting
- [x] **Phase 2: Backend Vertical Slice** - Full backend vote-casting and results API working end-to-end
- [ ] **Phase 3: Flutter Wiring** - End-to-end working vote-casting UI with real data

---

## Phase Details

### Phase 1: Schema & Domain Core
**Goal**: The votes table exists in the database and pure domain validation rules for vote-casting are codified and testable without any infrastructure dependency
**Depends on**: Nothing (builds on Phase 0 existing codebase)
**Requirements**: VOTE-02, VOTE-03, VOTE-04
**Success Criteria** (what must be TRUE):
  1. Running the backend applies V7 Flyway migration and the `votes` table exists with a UNIQUE constraint on `(voter_id, election_id)` and appropriate indexes
  2. A second attempt to insert a vote for the same voter+election pair is rejected by the database constraint (23505) before it can reach application code
  3. `CastVoteLogic` rejects a vote when the election's start/end window (UTC) does not include the current instant, returning `ElectionNotActive` without touching the database
  4. `CastVoteLogic` rejects a vote when the candidate's `electionId` does not match the target election, returning `CandidateNotInElection` without touching the database
**Plans**: 2 plans
Plans:
- [x] 01-01-PLAN.md — V7 migration + Vote.scala + VoteError.scala (schema and domain types)
- [x] 01-02-PLAN.md — CastVoteLogic.scala + CastVoteLogicSuite.scala (pure validation + tests)

### Phase 2: Backend Vertical Slice
**Goal**: An authenticated voter can submit a vote via the GraphQL API and an admin can query vote counts — both paths enforce all business rules and audit correctly
**Depends on**: Phase 1
**Requirements**: VOTE-01, VOTE-02, VOTE-03, VOTE-04, VOTE-05, RSLT-01, RSLT-02, RSLT-03, AUDT-01
**Success Criteria** (what must be TRUE):
  1. A voter with a valid JWT can call the `castVote` mutation and receive a success payload; the vote row appears in the `votes` table
  2. A voter calling `castVote` a second time for the same election receives a typed `AlreadyVoted` error response (not a 500 or raw JDBC error), whether the duplicate is caught by the application pre-check or the DB UNIQUE constraint
  3. A request to `castVote` without a valid JWT is rejected at the GraphQL resolver guard before any use-case logic executes
  4. The `electionResults` query returns a count per candidate including candidates with zero votes; calling it without an admin JWT returns an authorisation error
  5. Every successful `castVote` call writes a `VOTE_CAST` row to `audit_log` containing `voterId` and `electionId` — the `candidateId` is absent from that row
**Plans**: 4 plans
Plans:
- [x] 02-01-PLAN.md — VoteCount type, VoteRepository trait, CastVoteAlg+UseCase, GetVoteResultsAlg+UseCase (application layer)
- [x] 02-02-PLAN.md — DoobieVoteRepository: save with PSQLException 23505 guard, LEFT JOIN results query (infrastructure)
- [x] 02-03-PLAN.md — AuditedCastVoteUseCase: VOTE_CAST audit with voterId only, no candidateId (AOP)
- [x] 02-04-PLAN.md — ElectionSchema vote types, ElectionContext extension, castVote mutation, electionResults query, Main.scala wiring (API + wiring)

### Phase 3: Flutter Wiring
**Goal**: End-to-end working vote-casting UI with real data — VoteScreen consumes real candidates from route arguments, calls the backend mutation, and handles all server-defined outcomes correctly
**Depends on**: Phase 2
**Requirements**: FRNT-01, FRNT-02, FRNT-03, FRNT-04, FRNT-05
**Success Criteria** (what must be TRUE):
  1. Navigating from ElectionDetailScreen to VoteScreen shows the actual candidates fetched for that election — no hardcoded mock candidates appear
  2. Tapping the VOTAR button while a mutation is in flight disables the button and shows a loading indicator; a second tap before the response arrives has no effect
  3. When the server returns `AlreadyVoted`, VoteScreen displays a specific "already voted" message and the VOTAR button remains disabled — the screen does not crash or show a generic error
  4. The admin Results tab displays per-candidate vote counts sourced from the `electionResults` query instead of the static placeholder
  5. Election active-window checks in Flutter use UTC throughout — the same election that the backend marks as active is also displayed as active in the UI regardless of the device's local timezone
**Plans**: TBD
**UI hint**: yes

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Schema & Domain Core | 2/2 | Complete ✓ | 2026-05-22 |
| 2. Backend Vertical Slice | 4/4 | Complete ✓ | 2026-05-22 |
| 3. Flutter Wiring | 0/0 | Not started | - |

---

## Coverage Map

| Requirement | Phase | Description |
|-------------|-------|-------------|
| VOTE-01 | Phase 2 | Authenticated voter submits a vote for a candidate in an active election |
| VOTE-02 | Phase 1 | Duplicate vote rejected with typed `AlreadyVoted` error |
| VOTE-03 | Phase 1 | Vote rejected when election is not active (UTC window check) |
| VOTE-04 | Phase 1 | Vote rejected when candidate does not belong to the election |
| VOTE-05 | Phase 2 | Only voters with valid JWT can vote (GraphQL resolver guard) |
| RSLT-01 | Phase 2 | Admin queries vote counts per candidate via `electionResults` |
| RSLT-02 | Phase 2 | Results include candidates with zero votes (LEFT JOIN) |
| RSLT-03 | Phase 2 | `electionResults` is admin-only (explicit guard in QueryType) |
| AUDT-01 | Phase 2 | VoteCast event written to audit_log with electionId+voterId only (no candidateId) |
| FRNT-01 | Phase 3 | VoteScreen receives real candidates via VoteScreenArgs route argument |
| FRNT-02 | Phase 3 | VoteScreen blocks interaction during mutation (_submitting flag) |
| FRNT-03 | Phase 3 | VoteScreen handles AlreadyVoted with specific message and locked UI |
| FRNT-04 | Phase 3 | Admin Results tab shows real vote counts replacing placeholder |
| FRNT-05 | Phase 3 | Election date comparisons use UTC in all Flutter contexts |

**Unmapped v1 requirements:** 0
**Coverage:** 14/14 ✓

---

*Roadmap created: 2026-05-21*
*Last updated: 2026-05-22 — Phase 2 plans created (02-01, 02-02, 02-03, 02-04)*
