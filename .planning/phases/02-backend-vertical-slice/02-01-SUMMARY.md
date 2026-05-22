---
phase: 02-backend-vertical-slice
plan: "01"
subsystem: backend-voting-contracts
tags: [scala, cats-effect, tagless-final, domain, application, voting]
dependency_graph:
  requires: [01-01-SUMMARY.md, 01-02-SUMMARY.md]
  provides: [VoteCount, VoteRepository, CastVoteAlg, CastVoteUseCase, GetVoteResultsAlg, GetVoteResultsUseCase]
  affects: [02-02-DoobieVoteRepository, 02-03-AuditedCastVoteUseCase, 02-04-GraphQL]
tech_stack:
  added: []
  patterns: [EitherT pipeline, Tagless Final Alg/UseCase, value-class UUID wrapping]
key_files:
  created:
    - backend/src/main/scala/pt/ipp/estg/elections/voting/domain/VoteCount.scala
    - backend/src/main/scala/pt/ipp/estg/elections/voting/domain/VoteRepository.scala
    - backend/src/main/scala/pt/ipp/estg/elections/voting/application/CastVoteAlg.scala
    - backend/src/main/scala/pt/ipp/estg/elections/voting/application/CastVoteUseCase.scala
    - backend/src/main/scala/pt/ipp/estg/elections/voting/application/GetVoteResultsAlg.scala
    - backend/src/main/scala/pt/ipp/estg/elections/voting/application/GetVoteResultsUseCase.scala
  modified: []
decisions:
  - "VoteRepository.save returns F[Either[VoteError, Unit]] not F[Unit] — forces AlreadyVoted handling at compile time"
  - "CastVoteUseCase wraps UUID.randomUUID() in Sync[F].delay via EitherT.liftF for referential transparency"
  - "Election not found maps to ElectionNotActive VoteError (no ElectionNotFound variant exists in ADT)"
  - "Candidate membership validated via findByElection list .find — per codebase_facts decision 7"
metrics:
  duration: "~8 minutes"
  completed: "2026-05-22"
  tasks_completed: 2
  files_created: 6
  files_modified: 0
---

# Phase 2 Plan 01: Backend Application Contracts Summary

**One-liner:** CastVoteUseCase EitherT pipeline + VoteRepository/GetVoteResultsUseCase contracts using Tagless Final — establishes compile-time contract for Wave 2 infrastructure plans.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | VoteCount domain type and VoteRepository trait | bb052a6 | VoteCount.scala, VoteRepository.scala |
| 2 | CastVoteAlg, CastVoteUseCase, GetVoteResultsAlg, GetVoteResultsUseCase | 356ef64 | 4 application files |

## What Was Built

Six new Scala files establishing the full application/domain contract layer for vote-casting and results retrieval:

**Domain layer (voting/domain/):**
- `VoteCount.scala` — pure case class aggregating `(candidateId, candidateName, count)` for results display
- `VoteRepository[F]` — trait with `save(Vote): F[Either[VoteError, Unit]]` and `countByElection(ElectionId): F[List[VoteCount]]`

**Application layer (voting/application/):**
- `CastVoteAlg[F]` — trait with `execute(voterId, electionId, candidateId, ip): F[Either[VoteError, Vote]]`
- `CastVoteUseCase[F]` — EitherT pipeline: load election → load candidates → find candidate → get now → validate via `CastVoteLogic.validate` → generate VoteId → save vote
- `GetVoteResultsAlg[F]` — trait with `execute(electionId: UUID): F[List[VoteCount]]`
- `GetVoteResultsUseCase[F]` — simple delegation to `voteRepo.countByElection`

## Verification Results

- `sbt compile` exits 0
- `sbt test` exits 0 — all 9 pre-existing tests pass (5 CastVoteLogicSuite + 4 RegisterVoterUseCaseSuite)
- All 6 new files declare `package pt.ipp.estg.election.voting.*` (singular — not elections.*)
- `CastVoteUseCase extends CastVoteAlg[F]` confirmed (grep count: 1)
- `GetVoteResultsUseCase extends GetVoteResultsAlg[F]` confirmed (grep count: 1)
- `CastVoteLogic.validate` called exactly once in CastVoteUseCase pipeline (grep count: 1)

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| `VoteRepository.save` returns `F[Either[VoteError, Unit]]` | Forces AlreadyVoted handling at compile time; DoobieVoteRepository (Wave 2) maps PSQLException 23505 to Left(AlreadyVoted) |
| UUID.randomUUID() wrapped in Sync[F].delay | Referential transparency — side-effectful randomness lifted into F via EitherT.liftF |
| ElectionNotFound maps to ElectionNotActive | No `ElectionNotFound` variant exists in VoteError ADT; ElectionNotActive is semantically closest |
| Candidate membership via `findByElection.find` | Consistent with codebase_facts decision 7; validates candidate belongs to the specific election |

## Threat Model Compliance

| Threat ID | Status |
|-----------|--------|
| T-02-01 Tampering — UUID wrapping | Mitigated: voterId, electionId, candidateId all wrapped in VoterId, ElectionId, CandidateId before domain calls |
| T-02-02 Elevation — AlreadyVoted mapping | Mitigated: VoteRepository.save return type is F[Either[VoteError, Unit]], not F[Unit] |
| T-02-03 Info Disclosure — no auth at this layer | Accepted: auth enforced at GraphQL layer (Plan 02-04) |
| T-02-SC — no new dependencies | Accepted: build.sbt unchanged |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — this plan creates contract types only; no UI rendering or data sources involved.

## Self-Check: PASSED

- VoteCount.scala: FOUND
- VoteRepository.scala: FOUND
- CastVoteAlg.scala: FOUND
- CastVoteUseCase.scala: FOUND
- GetVoteResultsAlg.scala: FOUND
- GetVoteResultsUseCase.scala: FOUND
- Commit bb052a6: FOUND
- Commit 356ef64: FOUND
