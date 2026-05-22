---
phase: 02-backend-vertical-slice
plan: "04"
subsystem: api-graphql
tags: [scala, sangria, graphql, cats-effect, tagless-final, vote, mutation, query]
dependency_graph:
  requires:
    - 02-01 (CastVoteAlg, GetVoteResultsAlg, CastVoteUseCase, GetVoteResultsUseCase)
    - 02-02 (DoobieVoteRepository)
    - 02-03 (AuditedCastVoteUseCase)
  provides:
    - castVote GraphQL mutation (auth-guarded, maps VoteError ADT to Portuguese messages)
    - electionResults GraphQL query (admin-only guard, Future.failed on auth failure)
    - ElectionContext with castVoteUseCase and getVoteResultsUseCase fields
    - Main.scala fully wired with DoobieVoteRepository + AuditedCastVoteUseCase + GetVoteResultsUseCase
  affects:
    - Phase 3 Flutter frontend (VoteScreen will call castVote mutation)
tech-stack:
  added: []
  patterns:
    - Sangria UnionType for castVote payload (CastVoteSuccess | CastVoteError)
    - Future.failed(new Exception(...)) for admin-guard authorisation errors (returns proper GraphQL errors array)
    - IO.fromTry wrapping UUID.fromString for type-safe UUID parsing in resolvers
    - dispatcher.unsafeToFuture bridging IO to Future for Sangria resolvers
key-files:
  created: []
  modified:
    - backend/src/main/scala/pt/ipp/estg/elections/api/graphql/schemas/ElectionSchema.scala
    - backend/src/main/scala/pt/ipp/estg/elections/api/graphql/ElectionContext.scala
    - backend/src/main/scala/pt/ipp/estg/elections/api/graphql/MutationType.scala
    - backend/src/main/scala/pt/ipp/estg/elections/api/graphql/QueryType.scala
    - backend/src/main/scala/pt/ipp/estg/elections/Main.scala
key-decisions:
  - "Future.failed(new Exception(...)) used for electionResults auth guard — returns proper GraphQL error in errors array, not silent empty list"
  - "Reused existing ElectionIdArg in QueryType.electionResults — no duplicate Argument definitions"
  - "CastVote auth guard uses Future.successful(CastVoteErrorPayload(...)) — voter-facing error embedded in union type payload, not GraphQL error array"
  - "electionResults admin guard uses Future.failed — admin sees a hard error, not empty data, distinguishing unauthorised from no-results"
  - "Worktree rebased onto 4fc6663 to inherit voting/ and aop/AuditedCastVoteUseCase files from prior wave commits"
patterns-established:
  - "Admin-guard pattern for queries: Future.failed(new Exception(...)) — first established here for electionResults"
  - "Voter-guard pattern for mutations: Future.successful(ErrorPayload(...)) — consistent with existing addCandidate/createElection voter guards"
requirements-completed: [VOTE-01, VOTE-05, RSLT-01, RSLT-02, RSLT-03]
duration: ~12min
completed: "2026-05-22"
---

# Phase 2 Plan 04: GraphQL Wiring Summary

**Full backend vertical slice wired end-to-end: castVote mutation with voter auth guard, electionResults admin-only query, ElectionContext extended with two new use-case fields, Main.scala fully wired with DoobieVoteRepository + AuditedCastVoteUseCase + GetVoteResultsUseCase.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-05-22T14:05:00Z
- **Completed:** 2026-05-22T14:17:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- ElectionSchema.scala extended with CastVotePayload/CastVoteErrorPayload case classes, CastVoteSuccessPayloadType/CastVoteErrorPayloadType ObjectTypes, CastVotePayloadType union, VoteCountPayload case class, VoteCountPayloadType ObjectType
- ElectionContext.scala extended with `castVoteUseCase: CastVoteAlg[IO]` and `getVoteResultsUseCase: GetVoteResultsAlg[IO]` fields (placed after listElectionCandidatesUseCase, before authenticatedVoter)
- Main.scala wired DoobieVoteRepository, CastVoteUseCase, AuditedCastVoteUseCase, GetVoteResultsUseCase; ElectionContext constructor updated
- MutationType.scala: castVote mutation added with voter auth guard, VoterIdArg/CandidateIdArg, UUID parsing, full VoteError case match with Portuguese messages
- QueryType.scala: electionResults query added with dual admin guard (isEmpty + !isAdmin), Future.failed for auth errors, VoteCount -> VoteCountPayload mapping

## Task Commits

Each task was committed atomically:

1. **Task 1: ElectionSchema vote types + ElectionContext extension** - `7b08e31` (feat)
2. **Task 2: castVote mutation + electionResults query** - `bb17bb2` (feat)

## Files Created/Modified

- `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/schemas/ElectionSchema.scala` - added CastVotePayload, CastVoteErrorPayload, CastVoteSuccessPayloadType, CastVoteErrorPayloadType, CastVotePayloadType union, VoteCountPayload, VoteCountPayloadType
- `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/ElectionContext.scala` - added castVoteUseCase and getVoteResultsUseCase fields; added voting.application import
- `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/MutationType.scala` - added castVote Field with VoterIdArg/CandidateIdArg; added voting.domain import for VoteError cases
- `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/QueryType.scala` - added electionResults Field with admin guard; added Future import
- `backend/src/main/scala/pt/ipp/estg/elections/Main.scala` - added DoobieVoteRepository/CastVoteUseCase/AuditedCastVoteUseCase/GetVoteResultsUseCase instantiation; updated ElectionContext constructor call; added voting imports

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| `Future.failed(new Exception(...))` for electionResults auth guard | Returns error in GraphQL `errors` array - attacker cannot distinguish unauthorised from empty result set; per RSLT-03 requirement |
| `Future.successful(CastVoteErrorPayload(...))` for castVote auth guard | Union payload design - error is part of the type; consistent with existing mutation patterns (createElection, addCandidate) |
| Reused existing `ElectionIdArg` in QueryType | No duplicate Argument definitions needed; Sangria arg resolution is by position in field arguments list |
| Worktree rebased onto 4fc6663 | Worktree was initialised from fb441b1 (pre-voting commits); rebase onto main branch HEAD brought voting/ and aop/AuditedCastVoteUseCase.scala into worktree without merge commit overhead |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Worktree missing voting/ and AuditedCastVoteUseCase.scala**
- **Found during:** Task 1 (sbt compile failed with "value voting is not a member of pt.ipp.estg.election")
- **Issue:** Worktree was initialised from `fb441b1` (prior to Phase 2 wave 1-3 commits); voting/ package and aop/AuditedCastVoteUseCase.scala were absent in the worktree filesystem
- **Fix:** Committed Task 1 changes as a WIP commit, then `git rebase 4fc6663` to bring the worktree up to date with all prior wave commits; reset --soft HEAD~1 to unwrap the WIP commit before the final task commit
- **Files modified:** (worktree git history only - no source file changes)
- **Verification:** `sbt compile` exits 0 after rebase
- **Committed in:** 7b08e31 (Task 1 feat commit, post-rebase)

---

**Total deviations:** 1 auto-fixed (1 blocking - missing worktree files)
**Impact on plan:** Auto-fix necessary to proceed; source code unchanged from plan specification.

## Verification Results

- `sbt compile` exits 0 after Task 1 commit - PASSED
- `sbt compile` exits 0 after Task 2 commit - PASSED
- `sbt test` exits 0 - Total 9, Failed 0, Errors 0, Passed 9 - PASSED
- `grep -c '"castVote"' MutationType.scala` returns 1 - PASSED
- `grep -c '"electionResults"' QueryType.scala` returns 1 - PASSED
- `grep -c 'authenticatedVoter.isEmpty' QueryType.scala` returns 1 - PASSED
- `grep -c 'isAdmin' QueryType.scala` returns 1 - PASSED
- `grep -c 'DoobieVoteRepository' Main.scala` returns 2 - PASSED
- `grep -c 'AuditedCastVoteUseCase' Main.scala` returns 2 - PASSED
- `grep -c 'castVoteUseCase' ElectionContext.scala` returns 1 - PASSED

## Threat Model Compliance

| Threat ID | Status |
|-----------|--------|
| T-02-09 Elevation - castVote unauthenticated access | Mitigated: `if (ctx.ctx.authenticatedVoter.isEmpty) Future.successful(CastVoteErrorPayload("Autenticacao necessaria."))` before any use-case call |
| T-02-10 Elevation - electionResults non-admin access | Mitigated: isEmpty check then !isAdmin check; returns `Future.failed(new Exception(...))` |
| T-02-11 Tampering - UUID parsing in castVote | Mitigated: `IO.fromTry(for { vId <- Try(UUID.fromString(...)); ... })` for all three IDs; invalid UUID handled by `.handleError(_ => CastVoteErrorPayload("Identificadores invalidos."))` |
| T-02-12 Info Disclosure - electionResults partial result on auth failure | Mitigated: `Future.failed` returns no data; attacker cannot distinguish unauthorised from empty result |
| T-02-13 Tampering - voteRepo shared between use cases | Accepted: Doobie is stateless per-query; no shared mutable state |

## Known Stubs

None - all five files implement real logic; no placeholder data or TODO markers.

## Issues Encountered

The worktree was initialised from `fb441b1` (the merge commit that preceded all Phase 2 wave commits). When Task 1 modifications triggered `sbt compile`, the compiler could not find `pt.ipp.estg.election.voting.*` or `AuditedCastVoteUseCase` because those files were never checked out in the worktree. Resolution: WIP commit + `git rebase 4fc6663` + `git reset --soft HEAD~1` to bring worktree up to date without abandoning local changes.

## Next Phase Readiness

- Full backend vertical slice complete: castVote mutation and electionResults query are live
- PostgreSQL schema (V7 migration), domain logic, infrastructure, AOP, and GraphQL layers all integrated
- Phase 3 (Flutter frontend) can now call `castVote(voterId, electionId, candidateId)` mutation and receive typed union response
- Open question for Phase 3: server-derived `hasVoted` state strategy - see STATE.md

## Self-Check: PASSED

- ElectionSchema.scala contains "CastVotePayloadType": FOUND
- ElectionSchema.scala contains "VoteCountPayloadType": FOUND
- ElectionContext.scala contains "castVoteUseCase": FOUND
- Main.scala contains "DoobieVoteRepository": FOUND
- MutationType.scala contains "castVote": FOUND
- QueryType.scala contains "electionResults": FOUND
- Commit 7b08e31: FOUND
- Commit bb17bb2: FOUND
- sbt compile: exits 0
- sbt test: exits 0 (9/9 pass)

---
*Phase: 02-backend-vertical-slice*
*Completed: 2026-05-22*
