---
phase: 02-backend-vertical-slice
plan: "02"
subsystem: voting-infrastructure
tags: [infrastructure, scala, doobie, postgresql, voting]
dependency_graph:
  requires:
    - 02-01 (VoteRepository trait, VoteCount, Vote domain types)
  provides:
    - DoobieVoteRepository[F] — VoteRepository implementation
  affects:
    - backend/src/main/scala/pt/ipp/estg/elections/voting/infrastructure/
tech_stack:
  added: []
  patterns:
    - MonadCancelThrow constraint (matches DoobieCandidateRepository pattern)
    - PSQLException SQLState 23505 caught via .attempt.map → Left(AlreadyVoted)
    - LEFT JOIN votes on candidates for zero-count inclusion
    - doobie sql interpolator + .transact(xa)
key_files:
  created:
    - backend/src/main/scala/pt/ipp/estg/elections/voting/infrastructure/DoobieVoteRepository.scala
  modified: []
decisions:
  - "PSQLException 23505 caught exclusively in DoobieVoteRepository — does not leak to use-case or GraphQL layers"
  - "LEFT JOIN ensures candidates with zero votes are included in countByElection results"
  - "MonadCancelThrow constraint sufficient — no Sync needed (no Instant.now() calls)"
  - "GROUP BY includes c.number to allow ORDER BY c.number (candidate ordering)"
metrics:
  duration: "~8 minutes"
  completed: "2026-05-22"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  files_modified: 0
---

# Phase 2 Plan 02: DoobieVoteRepository — Infrastructure Summary

**One-liner:** DoobieVoteRepository implements VoteRepository[F] with an INSERT + PSQLException 23505 guard for duplicate vote detection, and a LEFT JOIN aggregation query returning zero-count candidates.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | DoobieVoteRepository — save + countByElection | e1baba3 | DoobieVoteRepository.scala |

## What Was Built

### Task 1 — DoobieVoteRepository.scala

Created `backend/src/main/scala/pt/ipp/estg/elections/voting/infrastructure/DoobieVoteRepository.scala`:

- `class DoobieVoteRepository[F[_]: MonadCancelThrow](xa: Transactor[F]) extends VoteRepository[F]`
- `save(vote: Vote): F[Either[VoteError, Unit]]` — INSERT INTO votes, catches PSQLException SQLState 23505 → `Left(AlreadyVoted)`, re-throws other exceptions
- `countByElection(electionId: ElectionId): F[List[VoteCount]]` — LEFT JOIN candidates → votes, GROUP BY c.id + c.name + c.number, ORDER BY c.number, maps to `VoteCount(CandidateId, CandidateName, Long)`

## Verification Results

- Package: `pt.ipp.estg.election.voting.infrastructure` (singular) — PASSED
- `extends VoteRepository[F]` present — PASSED
- PSQLException 23505 guard: `case Left(e: PSQLException) if e.getSQLState == "23505" => Left(AlreadyVoted)` — PASSED
- LEFT JOIN present in countByElection query — PASSED
- `sbt compile` exits 0 — PASSED

## Deviations from Plan

None — plan executed as written.

## Known Stubs

None — DoobieVoteRepository is a full implementation backed by the real Doobie/PostgreSQL stack.

## Threat Flags

PSQLException 23505 is caught exclusively in this class and translated to `Left(AlreadyVoted)`. No DB error leaks to the use-case or GraphQL layers.

## Self-Check: PASSED

- `DoobieVoteRepository.scala` exists at `backend/src/main/scala/pt/ipp/estg/elections/voting/infrastructure/DoobieVoteRepository.scala`
- Commit `e1baba3` exists
