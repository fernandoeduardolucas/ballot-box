---
phase: 02-backend-vertical-slice
status: passed
verified: 2026-05-22
verifier: orchestrator + graphify
---

# Phase 2 Verification: Backend Vertical Slice

**Phase goal:** An authenticated voter can submit a vote via the GraphQL API and an admin can query vote counts — both paths enforce all business rules and audit correctly.

## Success Criteria Results

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| SC-1 | Voter with valid JWT calls `castVote` → vote persisted | ✓ PASS | MutationType.scala:143 field `castVote`; ElectionContext.scala:18 `castVoteUseCase`; Main.scala:134 wired |
| SC-2 | Second `castVote` for same election → typed `AlreadyVoted` (not 500) | ✓ PASS | DoobieVoteRepository.scala:23 catches PSQLException 23505 → `Left(AlreadyVoted)`; MutationType.scala:168 maps to `CastVoteErrorPayload("Já votou nesta eleição.")` |
| SC-3 | No valid JWT → rejected at resolver guard before use-case | ✓ PASS | MutationType.scala:147 `authenticatedVoter.isEmpty` guard returns `CastVoteErrorPayload` before line 163 `castVoteUseCase.execute` |
| SC-4 | `electionResults` returns counts including zero-vote candidates; non-admin → auth error | ✓ PASS | DoobieVoteRepository.scala:31 `LEFT JOIN votes`; QueryType.scala:67-70 `Future.failed(new Exception(...))` on auth failure (not empty list) |
| SC-5 | Every successful `castVote` writes `VOTE_CAST` audit with voterId + electionId; candidateId absent | ✓ PASS | AuditedCastVoteUseCase.scala:17 `reason=Some(electionId.toString)` on Right; grep `AuditEvent(` \| grep candidateId = 0 matches |

## Requirement Traceability

| Req ID | Description | Delivered By | Status |
|--------|-------------|--------------|--------|
| VOTE-01 | Authenticated voter submits vote | castVote mutation + CastVoteUseCase | ✓ |
| VOTE-02 | Duplicate vote → AlreadyVoted | DoobieVoteRepository 23505 guard | ✓ |
| VOTE-03 | Vote rejected outside election window | CastVoteLogic.validate (Phase 1) | ✓ |
| VOTE-04 | Vote rejected for wrong candidate | CastVoteLogic.validate (Phase 1) | ✓ |
| VOTE-05 | Only voters with valid JWT can vote | MutationType.castVote isEmpty guard | ✓ |
| RSLT-01 | Admin queries vote counts per candidate | electionResults query + GetVoteResultsUseCase | ✓ |
| RSLT-02 | Results include zero-vote candidates | DoobieVoteRepository LEFT JOIN | ✓ |
| RSLT-03 | `electionResults` admin-only | QueryType isEmpty + !isAdmin → Future.failed | ✓ |
| AUDT-01 | VOTE_CAST event with voterId + electionId only | AuditedCastVoteUseCase flatTap; candidateId grep = 0 | ✓ |

## Architecture Compliance

- **Clean Architecture boundary**: PSQLException 23505 caught exclusively in `DoobieVoteRepository` — not in UseCase or GraphQL layer ✓
- **Ballot secrecy**: `candidateId` present in `execute` signature but never passed to `AuditEvent` ✓
- **Tagless Final pattern**: All Alg traits and UseCase implementations follow F[_]-polymorphic pattern ✓
- **Sangria type names**: `CastVoteSuccessPayloadType` = ObjectType(`"CastVoteSuccess"`) + UnionType(`"CastVotePayload"`) — no collision ✓

## Automated Checks

```
sbt test: Total 9, Failed 0, Errors 0, Passed 9
sbt compile: [success] after all 4 plans merged
```

## Verdict

**PHASE 2: PASSED** — All 9 requirements delivered, all 5 success criteria met, sbt compile and sbt test green.
