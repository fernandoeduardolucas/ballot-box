---
phase: 02-backend-vertical-slice
plan: "03"
subsystem: backend-aop-audit
tags: [scala, cats-effect, tagless-final, aop, audit, ballot-secrecy]
dependency_graph:
  requires: [02-01-SUMMARY.md]
  provides: [AuditedCastVoteUseCase]
  affects: [02-04-GraphQL, 02-05-wiring-Main]
tech_stack:
  added: []
  patterns: [Decorator/AOP, flatTap audit pattern, Tagless Final]
key_files:
  created:
    - backend/src/main/scala/pt/ipp/estg/elections/aop/AuditedCastVoteUseCase.scala
  modified: []
decisions:
  - "candidateId forwarded to target.execute but never serialised into AuditEvent — ballot secrecy enforced at compile level"
  - "civilId field repurposed to carry voterId.toString for VOTE_CAST events (consistent with AuditedLoginUseCase pattern)"
  - "electionId.toString placed in reason field for Right case — provides traceability without revealing ballot choice"
metrics:
  duration: "~4 minutes"
  completed: "2026-05-22"
  tasks_completed: 1
  files_created: 1
  files_modified: 0
---

# Phase 2 Plan 03: AuditedCastVoteUseCase Summary

**One-liner:** AOP decorator wrapping CastVoteAlg[F] with flatTap-based VOTE_CAST audit that records voterId+electionId only — candidateId excluded by design for ballot secrecy.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | AuditedCastVoteUseCase — VOTE_CAST audit with no candidateId | f22b033 | AuditedCastVoteUseCase.scala |

## What Was Built

**AOP layer (aop/):**
- `AuditedCastVoteUseCase[F]` — decorator that wraps `CastVoteAlg[F]`, implementing the same `flatTap` pattern used in `AuditedLoginUseCase`. On every `execute` call (success or failure), it records a `VOTE_CAST` `AuditEvent` containing:
  - `civilId = Some(voterId.toString)` — voter identity only
  - `ip` — request origin
  - `success = true/false` — based on `Right`/`Left`
  - `reason = Some(electionId.toString)` on success; `Some(error.toString)` on failure
  - `candidateId` is received as a parameter and forwarded to `target.execute` but is **never** passed to `AuditEvent`

## Verification Results

- `sbt compile` exits 0
- `sbt test` exits 0 — all 9 pre-existing tests pass (5 CastVoteLogicSuite + 4 RegisterVoterUseCaseSuite)
- `grep -c "VOTE_CAST"` returns 2 (eventType string appears in both Right and Left branches)
- `grep -c "voterId.toString"` returns 2 (present in both audit calls)
- `grep -c "electionId.toString"` returns 1 (present in Right branch reason field)
- `grep -c "flatTap"` returns 1
- `grep 'AuditEvent(' | grep -c 'candidateId'` returns 0 — ballot secrecy confirmed

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| candidateId absent from all AuditEvent calls | CLAUDE.md constraint: logging candidate choice creates permanent voter-to-candidate mapping in audit_log — violates ballot secrecy |
| flatTap handles both Right and Left | Matches AuditedLoginUseCase pattern exactly; ensures every vote attempt (success or failure) is audited — mitigates T-02-08 repudiation threat |
| civilId field carries voterId.toString | AuditEvent schema has no voterId field; civilId is semantically closest and consistently used for voter identification across all audit events |

## Threat Model Compliance

| Threat ID | Status |
|-----------|--------|
| T-02-07 Information Disclosure — ballot secrecy | Mitigated: grep confirms 0 occurrences of candidateId in AuditEvent constructor calls |
| T-02-08 Repudiation — missing audit on failed votes | Mitigated: flatTap pattern covers both Right(_) and Left(error) branches |
| T-02-SC Tampering — no new package installs | Accepted: build.sbt unchanged |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — this plan creates an AOP decorator only; no UI rendering or data sources involved.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

- AuditedCastVoteUseCase.scala: FOUND at backend/src/main/scala/pt/ipp/estg/elections/aop/AuditedCastVoteUseCase.scala
- Commit f22b033: FOUND
- sbt compile: exits 0
- sbt test: exits 0 (9/9 pass)
- candidateId in AuditEvent calls: 0 (PASS)
