---
phase: 03
phase-slug: flutter-wiring
date: 2026-05-22
---

# Validation Strategy — Phase 3: Flutter Wiring

## Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (dev_dependencies in pubspec.yaml) |
| Quick run | `cd frontend && flutter test` |
| Full run | `cd frontend && flutter test --reporter expanded` |
| Static analysis | `cd frontend && flutter analyze lib/` |

## Phase Requirements → Test Map

| Req ID | Behavior | Validation Type | Command / Check | File |
|--------|----------|-----------------|-----------------|------|
| FRNT-01 | VoteScreen renders candidates from VoteScreenArgs (no hardcoded list) | Static grep + flutter analyze | `grep -n "_candidates\|_Candidate" vote_screen.dart` → 0 matches | vote_screen.dart |
| FRNT-02 | VOTAR button disabled and shows spinner when `_submitting = true` | flutter analyze (type-checks guard) + manual smoke | `flutter analyze lib/` passes; verify in browser | vote_screen.dart |
| FRNT-03 | AlreadyVoted response renders `_AlreadyVotedBanner`, button disabled | flutter analyze + manual smoke | `flutter analyze lib/` passes; test with second vote | vote_screen.dart |
| FRNT-04 | Results tab shows per-candidate vote counts from electionResults query | flutter analyze + manual smoke | `flutter analyze lib/` passes; open Results tab as admin | main.dart |
| FRNT-05 | All date comparison sites use `DateTime.now().toUtc()` | Static grep | `grep -rn "DateTime.now()" frontend/lib/ \| grep -v "toUtc()"` → display-only hits only | main.dart, election_detail_screen.dart, active_elections_screen.dart |

## Sampling Rate

| Gate | Command |
|------|---------|
| Per task commit | `flutter analyze lib/<file>` (single file) |
| Per wave merge | `flutter analyze lib/` (all files) |
| Phase gate | `flutter analyze lib/` clean + manual smoke test with running backend |

## Wave 0 Gaps

The `frontend/test/` directory is empty — no widget tests exist.

Given the project scope (university TP2), the approved validation strategy for this phase is:

1. **Static analysis:** `flutter analyze lib/` must pass with 0 errors after each wave
2. **Static grep:** FRNT-05 UTC fix verified by grep (zero bare `DateTime.now()` comparison hits)
3. **Manual smoke test:** Navigate elections → detail → vote flow end-to-end with backend running
   - Confirm candidate list is real (from backend, not hardcoded)
   - Confirm VOTAR button shows spinner on tap
   - Confirm AlreadyVoted message on second submission
   - Confirm Results tab shows per-candidate counts (admin login)

Optional widget test files (can be created if time permits — not blocking phase completion):
- `frontend/test/vote_screen_test.dart` — mock VoteService; test `_submitting` and `_alreadyVoted` state transitions
- `frontend/test/resultados_section_test.dart` — stub service; verify `_ResultadosSection` renders VoteCountItem rows

## Phase Gate

Phase 3 passes when:
1. `cd frontend && flutter analyze lib/` exits 0
2. Grep for bare `DateTime.now()` in comparison context returns 0 results
3. Manual smoke test confirms VoteScreen shows real candidates and all mutation outcomes work
