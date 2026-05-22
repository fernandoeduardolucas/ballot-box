# STATE — VotoSeguro Vote-Casting Module

**Project:** VotoSeguro — ballot-box
**Milestone:** Vote-Casting Feature
**Initialized:** 2026-05-21
**Last updated:** 2026-05-22 (Phase 3 planned)

---

## Project Reference

**Core Value:** Um eleitor autenticado consegue votar exactamente uma vez numa eleição activa — sem duplicados, sem race conditions — e o voto é persistido na base de dados.

**Current Focus:** Phase 3 planned — ready for execution

---

## Current Position

| Field | Value |
|-------|-------|
| Phase | 3 — Flutter Wiring |
| Plan | 0/3 complete (03-01 pending, 03-02 pending, 03-03 pending) |
| Status | Phase 3 planned — ready to execute |
| Branch | U.S-2 |

**Progress bar:**

```
Phase 1  [████████████████████]  100% ✓
Phase 2  [████████████████████]  100% ✓
Phase 3  [                    ]  0%   (planned, 3 plans)
─────────────────────────────────────
Overall  [█████████████       ]  67%  (2/3 phases complete)
```

---

## Performance Metrics

| Metric | Value |
|--------|-------|
| Plans complete | 6 |
| Plans in progress | 0 |
| Requirements delivered | 11/14 (VOTE-01..05, RSLT-01..03, AUDT-01) |
| Phases complete | 2/3 |
| Plans planned | 3 (Phase 3: 03-01, 03-02, 03-03) |

---

## Accumulated Context

### Key Decisions (Locked)

| Decision | Rationale |
|----------|-----------|
| UNIQUE constraint `(voter_id, election_id)` as concurrency guarantee | DB-level serializable; survives restarts; no application-level locking needed |
| PSQLException 23505 caught exclusively in `DoobieVoteRepository` | Clean Architecture boundary — DB errors must not leak to use-case or GraphQL layers |
| `AuditedCastVoteUseCase` must never log `candidateId` | Ballot secrecy — logging the candidate choice creates a permanent voter-to-candidate mapping in `audit_log` |
| Admin-only `electionResults` query | Product decision confirmed; non-admins cannot see results during voting |
| Candidates passed as route argument `VoteScreenArgs(election, candidates)` | Candidates already loaded in `ElectionDetailScreen`; avoids a second backend round-trip |
| V7 Flyway migration must be written completely before first backend run | Editing after first apply causes checksum corruption |

### Resolved Gaps

None yet.

### Open Questions

| Question | Options | Resolved |
|----------|---------|---------|
| Server-derived `hasVoted` state strategy | (A) Pass `hasVoted: Boolean` in VoteScreenArgs requiring a backend query on ElectionDetailScreen load; (B) treat `AlreadyVoted` mutation response as silent success state | No — resolve before Phase 3 planning |
| IP threading in `AuditedCastVoteUseCase` | (A) n/a — omit IP; (B) thread IP through `CastVoteAlg.execute` signature | No — resolve before Phase 2 planning |
| `CandidateRepository.findByElection` existence | Verify before Phase 2; add method if absent | No — check at start of Phase 2 |

### Blockers

None.

### Todos Carry-Forward

- Verify `CandidateRepository.findByElection` exists before implementing `CastVoteUseCase` (Phase 2)
- Decide server-derived voted state strategy before Phase 3 planning
- Confirm IP threading approach for `AuditedCastVoteUseCase` before Phase 2 planning

---

## Session Continuity

**To resume work:**
1. Read `.planning/ROADMAP.md` for phase goals and success criteria
2. Read `.planning/REQUIREMENTS.md` for full requirement list with traceability
3. Check this file for current phase, open questions, and blockers
4. Run `/gsd:plan-phase 1` to begin Phase 1 planning

**Existing codebase baseline (Phase 0 delivered):**
- Voter registration + login with JWT (civilId, nut3Region, isAdmin claims)
- Election creation + candidate management (admin-only mutations)
- Active election listing and candidate listing (public queries)
- Audit log for login and registration events
- Flyway migrations V1–V6 applied; V7 is the next migration slot
- Flutter: ActiveElectionsScreen, ElectionDetailScreen, VoteScreen (stub with hardcoded candidates)
- VoteScreen currently has no backend connection; route push from ElectionDetailScreen passes ElectionItem but VoteScreen ignores it

---

*State initialized: 2026-05-21*
