# Phase 3: Flutter Wiring — Research

**Researched:** 2026-05-22
**Domain:** Flutter — route argument passing, async mutation with loading guard, GraphQL sealed-class result handling, admin data tab, UTC date consistency
**Confidence:** HIGH

---

## Summary

Phase 3 is a pure Flutter layer change. The backend API (Phase 2) is verified and complete.
All five requirements (FRNT-01 through FRNT-05) are contained in the `frontend/` tree — no Scala
files change. The work breaks into four surgical change clusters: (1) threading `VoteScreenArgs`
from `ElectionDetailScreen` through `main.dart` routing into a rewritten `VoteScreen`, (2) adding
`VoteService` with the `castVote` mutation, (3) replacing the `_PlaceholderSection` for
"Resultados" with a `_ResultadosSection` that calls `electionResults`, and (4) replacing every
`DateTime.now()` date-comparison site with `DateTime.now().toUtc()`.

There are exactly two path mismatches already in the codebase that this phase must fix:
`active_elections_screen.dart` line 466 pushes `/elections/vote` with only `arguments: election`
(an `ElectionItem`), not a `VoteScreenArgs`, and the same applies to `election_detail_screen.dart`
line 67. Both callers need updating once `VoteScreenArgs` exists.

**Primary recommendation:** Define `VoteScreenArgs` as a `final class` in
`election_service.dart` (alongside `ElectionItem` and `CandidateItem`), update both callers to
pass `VoteScreenArgs(election: election, candidates: snapshot.data!)`, update `main.dart` to
extract `VoteScreenArgs` from route args, and rewrite `VoteScreen` to consume it. Add
`VoteService` in the same data layer. Replace the Results placeholder in `main.dart`.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FRNT-01 | VoteScreen receives real candidates via `VoteScreenArgs(election, candidates)` route arg; no hardcoded mock | Route-args pattern; `ElectionDetailScreen` already has `snapshot.data` at button-tap time; `VoteScreenArgs` class design |
| FRNT-02 | VoteScreen blocks interaction during mutation (`_submitting` flag; double-tap protection) | `StatefulWidget` `_submitting` bool; `if (_submitting) return` guard; `CircularProgressIndicator` in button |
| FRNT-03 | VoteScreen handles `AlreadyVoted` with specific message and locked UI; no crash | `CastVoteError` payload distinguishing; sealed `CastVoteResult`; `_alreadyVoted` flag distinct from `_voted` |
| FRNT-04 | Admin Results tab shows real per-candidate vote counts instead of placeholder | `_ResultadosSection` widget with `FutureBuilder`; `VoteService.getVoteResults`; election selector design |
| FRNT-05 | Election date comparisons use UTC throughout Flutter | `DateTime.now().toUtc()` at every comparison site; affects `active_elections_screen.dart`, `election_detail_screen.dart`, `main.dart` |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Vote submission | Frontend (UI mutation call) | API/Backend | Frontend calls GraphQL; backend enforces all business rules |
| Candidate list display | Frontend Client | — | Candidates passed as route args; no new network call in VoteScreen |
| Duplicate vote detection | Backend | Frontend (handle CastVoteError) | DB UNIQUE constraint + 23505 catch is server-side; frontend only renders the error message it receives |
| `_submitting` guard | Frontend Client | — | Pure UI state; prevents double-tap before server response |
| Vote results display | Frontend Client | API/Backend | Frontend fetches via `electionResults` query; admin JWT enforced server-side |
| UTC date comparison | Frontend Client | — | Dart `DateTime` arithmetic; backend already stores/returns UTC ISO8601 |
| Admin-only Results tab | Frontend Client | API/Backend | Frontend checks `AuthStore.instance.isAdmin`; backend enforces independently via `!isAdmin` guard |

---

## Standard Stack

### Core (already in pubspec.yaml — no new packages needed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter` SDK | ≥3.4.0 | UI framework | Project baseline |
| `http` | ^1.2.2 | HTTP transport for GraphQL | Already used by `GraphQLService` |
| `google_fonts` | ^6.2.1 | Typography (IBM Plex, Instrument Serif, Atkinson) | Already used across all screens |

**No new packages required.** All functionality is built on `GraphQLService.execute()` which
wraps `http`. No GraphQL client library is needed; the project uses a hand-rolled `GraphQLService`
which is the established pattern.

### New Data-Layer Types (Dart — no packages)

| Type | File | Purpose |
|------|------|---------|
| `VoteScreenArgs` | `election_service.dart` | Route argument bundle |
| `CastVoteResult` (sealed) | `election_service.dart` or new `vote_service.dart` | Typed mutation outcome |
| `CastVoteSuccess` | same | Success payload |
| `CastVoteAlreadyVoted` | same | `AlreadyVoted` outcome distinct from generic error |
| `CastVoteFailure` | same | Generic/other error |
| `VoteCountItem` | same | Per-candidate result row |
| `VoteService` | `vote_service.dart` | `castVote` + `getVoteResults` |

---

## Package Legitimacy Audit

No new packages are being installed. This section is N/A for Phase 3.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
ElectionDetailScreen (already has candidates in snapshot.data)
     │
     │  Navigator.pushNamed('/elections/vote',
     │    arguments: VoteScreenArgs(election, candidates))
     ▼
main.dart route factory
     │  extracts VoteScreenArgs from ModalRoute.settings.arguments
     ▼
VoteScreen(args: VoteScreenArgs)
     │  renders args.candidates list (real CandidateItems)
     │  on VOTAR confirm:
     ▼
VoteService.castVote(electionId, candidateId)
     │  GraphQLService.execute(castVote mutation)
     │  returns CastVoteResult (sealed)
     ├─ CastVoteSuccess    → set _voted = true, show _VotedBanner
     ├─ CastVoteAlreadyVoted → set _alreadyVoted = true, show _AlreadyVotedBanner
     └─ CastVoteFailure    → show SnackBar error, re-enable button

ActiveElectionsScreen (also pushes /elections/vote)
     │  currently passes only ElectionItem — must be updated to
     │  first push to /elections/detail (existing behaviour for VOTAR from list)
     │  OR must fetch candidates inline (too costly — see Pitfall 3)
     │  DECISION: VOTAR button on ActiveElectionsScreen keeps existing behaviour
     │  of pushing /elections/detail (not /elections/vote directly) — see below
```

**Important discovery on `active_elections_screen.dart`:**
Line 465-468 in `active_elections_screen.dart` has a "VOTAR" `FilledButton` that pushes
`/elections/vote` with only `arguments: election`. After Phase 3 changes the `/elections/vote`
route to expect a `VoteScreenArgs`, this will crash with a cast exception. The fix options are:
- Option A: Change that button to push `/elections/detail` instead (voter sees candidates
  first, then taps VOTAR from the detail screen). This is the correct UX — a voter should see
  candidates before voting.
- Option B: Fetch candidates inline before navigating, then push `VoteScreenArgs`.

Option A is recommended (simpler, better UX, consistent with CLAUDE.md intent that candidates
come from detail screen). The "VOTAR" shortcut on `ActiveElectionsScreen` becomes "VER E VOTAR"
navigating to `/elections/detail`.

### Recommended File Structure (changes only)

```
frontend/lib/
├── features/election/
│   ├── data/
│   │   ├── election_service.dart       # ADD: VoteScreenArgs class (at bottom)
│   │   └── vote_service.dart           # NEW: VoteService, CastVoteResult sealed class,
│   │                                   #      VoteCountItem, castVote(), getVoteResults()
│   └── presentation/screens/
│       ├── vote_screen.dart            # REWRITE: accept VoteScreenArgs, add _submitting,
│       │                               #   _alreadyVoted; replace _Candidate with CandidateItem
│       └── election_detail_screen.dart # MODIFY: pass VoteScreenArgs(election, candidates) to push
└── main.dart                           # MODIFY: /elections/vote route extracts VoteScreenArgs;
                                        #   _ResultadosSection replaces _PlaceholderSection for index 3;
                                        #   ActiveElectionsScreen VOTAR button → /elections/detail
```

### Pattern 1: VoteScreenArgs — Where to Define It

**What:** A simple immutable data class bundling `ElectionItem` and `List<CandidateItem>`.

**Where:** Define as a `final class` at the end of `election_service.dart`, alongside the other
data-layer types (`ElectionItem`, `CandidateItem`). This keeps all route data types co-located
with the data they contain, matching the existing project pattern (no separate `models/` folder).

```dart
// Source: Project convention from election_service.dart
final class VoteScreenArgs {
  const VoteScreenArgs({required this.election, required this.candidates});
  final ElectionItem election;
  final List<CandidateItem> candidates;
}
```

**Route factory in main.dart:**

```dart
'/elections/vote': (ctx) {
  final args = ModalRoute.of(ctx)!.settings.arguments as VoteScreenArgs;
  return VoteScreen(args: args);
},
```

**Caller in election_detail_screen.dart** (inside FutureBuilder where `snapshot.data` is available):

```dart
onPressed: AuthStore.instance.isAuthenticated
    ? () => Navigator.pushNamed(context, '/elections/vote',
          arguments: VoteScreenArgs(
            election: widget.election,
            candidates: snapshot.data!,
          ))
    : () => Navigator.pushNamed(context, '/auth/login'),
```

### Pattern 2: VoteService and CastVoteResult Sealed Class

**What:** A new service class following the exact same pattern as `ElectionService`. Sealed class
result mirrors `CreateElectionResult` pattern already in the codebase.

```dart
// Source: Project pattern from election_service.dart (CreateElectionResult)
sealed class CastVoteResult {}

final class CastVoteSuccess extends CastVoteResult {
  const CastVoteSuccess({required this.voteId, required this.electionId, required this.votedAt});
  final String voteId;
  final String electionId;
  final String votedAt;
}

final class CastVoteAlreadyVoted extends CastVoteResult {}

final class CastVoteFailure extends CastVoteResult {
  const CastVoteFailure({required this.message});
  final String message;
}
```

**VoteService.castVote:**

```dart
Future<CastVoteResult> castVote({
  required String electionId,
  required String candidateId,
}) async {
  const mutation = r'''
    mutation CastVote($electionId: String!, $candidateId: String!) {
      castVote(electionId: $electionId, candidateId: $candidateId) {
        ... on CastVoteSuccess {
          voteId
          electionId
          votedAt
        }
        ... on CastVoteError {
          message
        }
      }
    }
  ''';
  final result = await _graphql.execute(
    query: mutation,
    variables: {'electionId': electionId, 'candidateId': candidateId},
  );
  final data = result['data']?['castVote'] as Map<String, dynamic>?;
  if (data == null) return CastVoteFailure(message: 'Resposta inválida do servidor.');
  if (data.containsKey('voteId')) {
    return CastVoteSuccess(
      voteId: data['voteId'] as String,
      electionId: data['electionId'] as String,
      votedAt: data['votedAt'] as String,
    );
  }
  final message = data['message'] as String? ?? 'Erro desconhecido.';
  if (message == 'Já votou nesta eleição.') return CastVoteAlreadyVoted();
  return CastVoteFailure(message: message);
}
```

**Note on `voterId` argument:** The backend `castVote` mutation signature in Phase 2 plan
includes `voterId` as an argument (`VoterIdArg = Argument("voterId", StringType)`). However, the
JWT already identifies the voter server-side. Looking at the GraphQL spec defined in Phase 2
(`02-04-PLAN.md`), the mutation is:

```graphql
mutation CastVote($electionId: String!, $candidateId: String!)
```

The `voterId` in the resolver comes from `ctx.ctx.authenticatedVoter` (JWT), not from the client.
The client only sends `electionId` and `candidateId`. This is confirmed by the CLAUDE.md
constraint showing the mutation signature without `voterId`. The Flutter client must NOT send
`voterId` — it is extracted server-side from the JWT token.

**VoteCountItem and getVoteResults:**

```dart
class VoteCountItem {
  const VoteCountItem({required this.candidateId, required this.candidateName, required this.count});
  final String candidateId;
  final String candidateName;
  final int count;

  factory VoteCountItem.fromJson(Map<String, dynamic> json) => VoteCountItem(
    candidateId:   json['candidateId'] as String,
    candidateName: json['candidateName'] as String,
    count:         (json['count'] as int? ?? 0),
  );
}

Future<List<VoteCountItem>> getVoteResults(String electionId) async {
  const query = r'''
    query ElectionResults($electionId: String!) {
      electionResults(electionId: $electionId) {
        candidateId
        candidateName
        count
      }
    }
  ''';
  final result = await _graphql.execute(query: query, variables: {'electionId': electionId});
  final list = result['data']?['electionResults'] as List<dynamic>?;
  if (list == null) throw Exception('Resposta inválida do servidor.');
  return list.cast<Map<String, dynamic>>().map(VoteCountItem.fromJson).toList();
}
```

**Note on `count` type:** The backend returns `Long` (Sangria `LongType`). GraphQL serialises
`Long` as JSON integer. In Dart, JSON integers decode as `int` (Dart's `int` is 64-bit on
64-bit platforms). Cast as `int` is safe. [ASSUMED — JSON integer deserialization in Dart `http`
package with `jsonDecode`; standard Dart JSON behavior]

### Pattern 3: VoteScreen Rewrite with `_submitting` Guard

**Key state variables:**

```dart
class _VoteScreenState extends State<VoteScreen> {
  int? _selectedId;       // selected CandidateItem index in args.candidates
  bool _voted = false;    // successful vote submitted
  bool _alreadyVoted = false;  // server returned AlreadyVoted
  bool _submitting = false;    // mutation in flight (FRNT-02)

  String? _selectedCandidateId;  // the actual UUID string to pass to mutation

  // ...
}
```

**Replacing `_Candidate` with `CandidateItem`:**
`VoteScreen` currently uses private `_Candidate` objects with `partyColor`. `CandidateItem`
(from `election_service.dart`) has no `partyColor`. The cards should fall back to a consistent
color (e.g., `AppColors.primary`) when no party color is available, since real candidates from
the backend don't include a color field. The card layout can use `AppColors.primary` for the
number circle and selection border rather than a per-candidate color.

**`_confirmVote` becomes an async mutation call:**

```dart
Future<void> _confirmVote(CandidateItem candidate) async {
  final confirmed = await showDialog<bool>(context: context, builder: (ctx) => /* existing dialog */);
  if (confirmed != true || !mounted) return;

  setState(() => _submitting = true);
  try {
    final result = await _voteService.castVote(
      electionId: widget.args.election.id,
      candidateId: candidate.id,
    );
    if (!mounted) return;
    switch (result) {
      case CastVoteSuccess():
        setState(() { _voted = true; _submitting = false; });
      case CastVoteAlreadyVoted():
        setState(() { _alreadyVoted = true; _submitting = false; });
      case CastVoteFailure(:final message):
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
    }
  } catch (e) {
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro: ${e.toString()}')),
    );
  }
}
```

**`_VoteButton` must pass `_submitting` down:**

```dart
_VoteButton(
  enabled: selected != null && !_submitting,
  submitting: _submitting,
  onVote: () => _confirmVote(selected!),
),
```

Inside `_VoteButton.build`:

```dart
FilledButton.icon(
  onPressed: (enabled && !submitting) ? onVote : null,
  icon: submitting
      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
      : const Icon(Icons.how_to_vote_rounded),
  label: Text('VOTAR', ...),
  ...
),
```

### Pattern 4: AlreadyVoted State (FRNT-03) — Option B Recommendation

**Decision: Use Option B (treat AlreadyVoted mutation response as terminal state).**

Rationale:
- FRNT-03 only requires "VoteScreen handles AlreadyVoted with specific message and locked UI".
  It does NOT require pre-checking before the voter even tries.
- Option A (pass `hasVoted: Boolean` in `VoteScreenArgs`) requires an extra backend query on
  `ElectionDetailScreen` load, adding latency to every election detail view even for voters who
  haven't voted.
- Option B: voter taps confirm → mutation returns `CastVoteError` with message "Já votou nesta
  eleição." → Flutter maps this to `CastVoteAlreadyVoted()` → `_alreadyVoted = true` → show a
  distinct "Já Votou" banner and disable the button. This is clean, lazy, and correct.
- The `AlreadyVoted` message is exactly `"Já votou nesta eleição."` — confirmed in the Phase 2
  plan (`MutationType.scala` mapping `case Left(AlreadyVoted) => CastVoteErrorPayload("Já votou
  nesta eleição.")`). The Flutter client distinguishes it by exact string match.

**`_AlreadyVotedBanner` widget:** Reuse the `_VotedBanner` style but with a distinct message and
a different icon (e.g., `Icons.lock_outline_rounded`) and `AppColors.gold` color to visually
distinguish "already voted elsewhere" from "just voted now".

### Pattern 5: Results Tab (_ResultadosSection for FRNT-04)

**What the current code provides:**
- `main.dart` line 180: `3 => const _PlaceholderSection(title: 'Resultados', ...)`
- The `_EleicoesAdminSection` (index 1) already demonstrates the FutureBuilder + election-list
  expand pattern with candidates.

**Results tab design decision — Election Selector:**
The Results tab needs an election selector because `electionResults` requires a specific
`electionId`. Three options:
- A: Show dropdown of all elections at top of tab; results load for selected election.
- B: Replicate `_EleicoesAdminSection` pattern — expandable list where each row expands to show
  results for that election.
- C: Show results for all elections inline (one results block per election) — loaded all at once.

**Recommendation: Option B** — Expandable list of elections, each expanding to show results.
This mirrors `_EleicoesAdminSection` exactly and is the lowest-implementation-risk approach. It
reuses the existing accordion pattern. The `_ResultadosSection` fetches all elections on load,
renders each as a collapsible row, and on expansion fetches results for that election ID.

```dart
class _ResultadosSection extends StatefulWidget { ... }

class _ResultadosSectionState extends State<_ResultadosSection> {
  final _electionService = ElectionService(GraphQLService(baseUrl: 'http://localhost:8080/graphql'));
  final _voteService = VoteService(GraphQLService(baseUrl: 'http://localhost:8080/graphql'));
  late Future<List<ElectionItem>> _electionsFuture;
  String? _expandedId;
  Future<List<VoteCountItem>>? _resultsFuture;

  // ... initState, _toggleElection, build with FutureBuilder<List<ElectionItem>>
}
```

**Admin guard in UI:** The Results tab (index 3) is only reachable from `HomePage` which is
admin-only (`/home` route, accessed via "Administração" button). However, to be safe, add an
`AuthStore.instance.isAdmin` check at the top of `_ResultadosSectionState.build`:

```dart
if (!AuthStore.instance.isAdmin) {
  return const Center(child: Text('Acesso restrito a administradores.'));
}
```

The backend enforces this independently (RSLT-03), so this is UI defense-in-depth only.

### Pattern 6: UTC Date Fix (FRNT-05)

**The actual bug:** Dart `DateTime.parse("2026-05-22T10:00:00Z")` returns a UTC DateTime (`.isUtc == true`). `DateTime.now()` returns local time (`.isUtc == false`). Arithmetic like `.difference()` and `.isAfter()` converts both to UTC internally, so the *result* is correct but the *displayed value* (`dt.hour`, `dt.minute`) is in UTC if the original is UTC and in local time if local.

**Affected files and lines:**

| File | Line(s) | Current Code | Fix |
|------|---------|--------------|-----|
| `active_elections_screen.dart` | 377, 379, 485-486 | `DateTime.now()` for `remaining`, `_progressValue` | `DateTime.now().toUtc()` |
| `election_detail_screen.dart` | 166, 220-221 | `DateTime.now()` for status chip and `_progressValue` | `DateTime.now().toUtc()` |
| `main.dart` `_ElectionAdminRow` | 665-667 | `DateTime.now()` for `ended`, `active` | `DateTime.now().toUtc()` |

**Display formatting (`_fmt`):** Currently calls `dt.hour`, `dt.minute` on a UTC DateTime,
which displays UTC hours. This is correct behaviour for this application (the backend stores
UTC times; displaying UTC hours is accurate and consistent). No change needed to `_fmt` methods.

**Minimum change for FRNT-05:** Replace `DateTime.now()` with `DateTime.now().toUtc()` at every
date-comparison site. No `toLocal()` conversion — the existing display already shows UTC which
is consistent with how the backend validates active windows.

### Anti-Patterns to Avoid

- **Fetching candidates again inside VoteScreen:** VoteScreen must never call
  `electionService.listElectionCandidates()` — candidates are already available in route args.
  Extra network call adds latency and violates the CLAUDE.md invariant.
- **Hardcoding the AlreadyVoted message:** Map by exact string match from `CastVoteError.message`.
  If the backend message changes, this needs updating. A safer future option is to add a
  discriminant field to `CastVoteError`, but that requires backend change — not in scope here.
- **Using `setState` after an async gap without `mounted` check:** Always check `if (!mounted) return;`
  after every `await` before calling `setState`. The vote screen can be popped mid-mutation.
- **Passing `VoteScreenArgs` null-unsafely:** The route cast `as VoteScreenArgs` will throw if
  navigated to `/elections/vote` without arguments. After Phase 3, `ActiveElectionsScreen` must
  NOT push `/elections/vote` directly — it must push `/elections/detail` instead.
- **`_submitting` flag not reset on error:** If `castVote` throws or returns `CastVoteFailure`,
  `_submitting` must be set back to `false`. Leaving it `true` permanently disables the button
  with no user feedback.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GraphQL HTTP transport | Custom fetch layer | `GraphQLService.execute()` | Already exists; tested against backend; handles auth header injection |
| JSON decoding | Custom parser | `jsonDecode` from `dart:convert` | Used by `GraphQLService` already |
| Loading indicator | Custom spinner widget | `CircularProgressIndicator` (Material) | Already used in `ElectionDetailScreen` and others |
| Snackbar error display | Custom error overlay | `ScaffoldMessenger.of(context).showSnackBar` | Used implicitly in Material; zero-boilerplate error feedback |

**Key insight:** Phase 3 adds zero new dependencies. Everything is composed from existing project
primitives.

---

## Common Pitfalls

### Pitfall 1: `_Candidate` private type vs `CandidateItem`
**What goes wrong:** `VoteScreen` uses `_Candidate` with `partyColor: Color`. `CandidateItem`
has no `partyColor`. Developers may try to preserve the color-coding by generating colors from
candidate data (e.g., hash of name). This adds unnecessary complexity.
**Why it happens:** The mock `_Candidate` was richly typed; real data is simpler.
**How to avoid:** Use `AppColors.primary` as the uniform card accent color. The card layout still
works — only the per-candidate color tinting is lost. Alternatively derive a deterministic color
from `candidate.number % color_palette.length` but this is cosmetic, not required.
**Warning signs:** Any reference to `candidate.partyColor` or `_Candidate` after the rewrite.

### Pitfall 2: `active_elections_screen.dart` VOTAR button crash
**What goes wrong:** After updating `main.dart` to cast route args as `VoteScreenArgs`, the
existing VOTAR shortcut button on `ActiveElectionsScreen` (line 465) will crash with
`type 'ElectionItem' is not a subtype of type 'VoteScreenArgs'`.
**Why it happens:** `active_elections_screen.dart` pushes `/elections/vote` with
`arguments: election` (only the `ElectionItem`). The route factory now expects `VoteScreenArgs`.
**How to avoid:** Change the VOTAR button on `ActiveElectionsScreen` to push
`/elections/detail` with `arguments: election`. The voter then taps VOTAR from `ElectionDetailScreen`
which passes the full `VoteScreenArgs`. This is actually better UX.
**Warning signs:** Runtime exception "type 'ElectionItem' is not a subtype of type 'VoteScreenArgs'"
when tapping VOTAR from the elections list.

### Pitfall 3: `count` field type from GraphQL (Long vs int)
**What goes wrong:** The backend's `VoteCountPayloadType` uses `LongType` for `count`. JSON
serialises this as a JSON number. Dart's `jsonDecode` will decode small numbers as `int` but
very large numbers (> 2^53) as... still `int` on 64-bit. However, if the developer casts as
`num` or fails to cast, runtime errors occur.
**How to avoid:** Cast as `(json['count'] as num).toInt()` to be safe across platforms (web
Dart uses 53-bit integers in JS; native uses 64-bit).
**Warning signs:** `type 'double' is not a subtype of type 'int'` or similar cast failures on web.

### Pitfall 4: VoteService `GraphQLService` instantiation duplication
**What goes wrong:** Every widget that needs a service hard-codes
`GraphQLService(baseUrl: 'http://localhost:8080/graphql')`. This already happens in
`ElectionDetailScreen`, `_EleicoesAdminSection`, and `ActiveElectionsScreen`. Phase 3 adds
another instantiation in `VoteScreen` and `_ResultadosSection`.
**How to avoid:** Follow the existing pattern (no DI container in use). Simply instantiate inline
as done elsewhere. This is a known tech debt but fixing it is out of scope for Phase 3.
**Warning signs:** Inconsistent base URLs across widgets (should all be `http://localhost:8080/graphql`).

### Pitfall 5: `castVote` mutation `voterId` argument
**What goes wrong:** Phase 2 plan shows `VoterIdArg` defined in `MutationType.scala`. A
developer reading only the Scala plan might try to pass `voterId` from Flutter. But the mutation
callable from the client is `castVote(electionId: String!, candidateId: String!)` — the `voterId`
is extracted server-side from the JWT.
**How to avoid:** The GraphQL mutation fragment in CLAUDE.md and in this research uses only
`$electionId` and `$candidateId`. Never pass `voterId` from the Flutter client.
**Warning signs:** GraphQL error "Unknown argument 'voterId'" at runtime.

### Pitfall 6: VoteScreen rebuild losing selection state mid-mutation
**What goes wrong:** `setState(() => _submitting = true)` triggers a rebuild. If candidate cards
derive selection state from `_selectedId`, the selection should be preserved. But if the rebuild
causes `_selectedId` to reset (e.g., if it's computed from a non-state variable), the user sees
their selection disappear while waiting.
**How to avoid:** `_selectedId` and `_selectedCandidateId` must be `State` fields (which they
are already — `int? _selectedId`). The rebuild with `_submitting = true` will correctly show the
spinner on the button while the selection remains visible. No extra action needed if the pattern
is followed correctly.

---

## Code Examples

### VoteScreenArgs class definition
```dart
// Source: Project pattern — election_service.dart (end of file)
final class VoteScreenArgs {
  const VoteScreenArgs({required this.election, required this.candidates});
  final ElectionItem election;
  final List<CandidateItem> candidates;
}
```

### Route update in main.dart
```dart
// Source: Existing pattern — main.dart line 138-141 (/elections/detail route)
'/elections/vote': (ctx) {
  final args = ModalRoute.of(ctx)!.settings.arguments as VoteScreenArgs;
  return VoteScreen(args: args);
},
```

### ElectionDetailScreen VOTAR button fix
```dart
// Source: election_detail_screen.dart line 65-69 (FutureBuilder snapshot context)
onPressed: AuthStore.instance.isAuthenticated
    ? () => Navigator.pushNamed(context, '/elections/vote',
          arguments: VoteScreenArgs(
            election: widget.election,
            candidates: snapshot.data!,
          ))
    : () => Navigator.pushNamed(context, '/auth/login'),
```

### ActiveElectionsScreen VOTAR → detail redirect
```dart
// Source: active_elections_screen.dart line 464-469 (change target route)
onPressed: () => Navigator.pushNamed(context, '/elections/detail',
    arguments: election),
```

### UTC fix — one-liner replacement
```dart
// Source: FRNT-05 requirement; applies to all DateTime.now() comparison sites
final now = DateTime.now().toUtc(); // was: DateTime.now()
```

### VoteScreen constructor and widget
```dart
// Source: Project pattern — ElectionDetailScreen constructor style
class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key, required this.args});
  final VoteScreenArgs args;

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}
```

### AlreadyVoted string discriminant
```dart
// Source: Phase 2 MutationType.scala — case Left(AlreadyVoted) => CastVoteErrorPayload("Já votou nesta eleição.")
const _kAlreadyVotedMessage = 'Já votou nesta eleição.';

// In VoteService.castVote:
if (message == _kAlreadyVotedMessage) return CastVoteAlreadyVoted();
return CastVoteFailure(message: message);
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `_Candidate` mock list hardcoded in `VoteScreen` | `VoteScreenArgs(election, candidates)` from route | Phase 3 | Real data flows from detail screen |
| No mutation on vote confirm | `VoteService.castVote` called in `_confirmVote` | Phase 3 | Votes actually persisted |
| `_PlaceholderSection` for Results tab | `_ResultadosSection` with `FutureBuilder` | Phase 3 | Admins see real counts |
| `DateTime.now()` (local) for comparisons | `DateTime.now().toUtc()` | Phase 3 | UTC consistency with backend |

**Deprecated/outdated:**
- `_Candidate` private class in `vote_screen.dart`: replaced by `CandidateItem` from data layer
- `const VoteScreen()` no-arg constructor: replaced by `VoteScreen(args: VoteScreenArgs)`
- `main.dart` line 137 `'/elections/vote': (_) => const VoteScreen()`: replaced by args-aware factory

---

## Open Questions (RESOLVED)

1. **`_Candidate.partyColor` replacement**
   - What we know: `CandidateItem` has no color field; the existing card UI uses per-candidate `partyColor`
   - What's unclear: whether the planner wants (a) uniform `AppColors.primary` for all cards or (b) deterministic color assignment from candidate number
   - Recommendation: Use `AppColors.primary` uniformly — it matches the existing primary action color and removes a cosmetic that was only there for mock data. Document this decision in the plan.
   - RESOLVED: Use `AppColors.primary` for all candidate card colors (uniform, no per-candidate color).

2. **`VoteScreen` header election title**
   - What we know: Header currently hardcodes "Eleições Presidenciais 2026." (from `_buildEditorialHeader`)
   - What's unclear: whether the header should show `args.election.title` instead
   - Recommendation: Use `args.election.title` — the hardcoded title is clearly from the mock era.
   - RESOLVED: Use `args.election.title` in the header (hardcoded string is from mock era, must be removed).

3. **`_StatusBar` countdown hardcode**
   - What we know: `_StatusBar` shows "Encerra em 2h 45m" hardcoded; `args.election.endDate` is available
   - What's unclear: whether a live countdown is required or a one-time computed display
   - Recommendation: Compute `remaining = args.election.endDate.toUtc().difference(DateTime.now().toUtc())` at build time (not a live ticker) and display the result. This is consistent with how `ElectionDetailScreen` does it.
   - RESOLVED: Compute remaining at build time from `args.election.endDate.toUtc()` — no live ticker needed.

4. **`getVoteResults` `count` field JSON type safety**
   - What we know: Backend serialises Scala `Long` as JSON integer; Dart/web decodes as `int`/`double` depending on magnitude
   - Recommendation: Cast as `(json['count'] as num).toInt()` for cross-platform safety. [ASSUMED: Dart web `jsonDecode` behavior on large integers]
   - RESOLVED: Use `(json['count'] as num).toInt()` in `VoteCountItem.fromJson` for web-safe deserialization.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All frontend changes | Not checked (dev machine) | ≥3.4.0 (pubspec) | — |
| Backend on :8080 | End-to-end manual testing | Not checked (runtime) | Phase 2 | Cannot test mutations without backend |
| PostgreSQL | Backend data layer | Not checked | Via Docker | `docker compose up -d postgres` |

**Missing dependencies with no fallback:**
- Backend must be running on `localhost:8080` for end-to-end vote testing. All widget-level
  logic can be verified without the backend; mutation testing requires the Phase 2 backend.

**Missing dependencies with fallback:**
- None; all Flutter code changes are independent of backend availability.

---

## Validation Architecture

`nyquist_validation` is `true` in `.planning/config.json`.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (already in dev_dependencies) |
| Config file | None — no `flutter_test` config file exists; framework discovered via pubspec.yaml |
| Quick run command | `cd frontend && flutter test` |
| Full suite command | `cd frontend && flutter test --reporter expanded` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FRNT-01 | `VoteScreen` renders candidates from `VoteScreenArgs` (not hardcoded) | unit/widget | `flutter test test/vote_screen_test.dart` | Wave 0 |
| FRNT-02 | Button disabled and shows spinner during `_submitting = true` | widget | `flutter test test/vote_screen_test.dart` | Wave 0 |
| FRNT-03 | `AlreadyVoted` response renders `_AlreadyVotedBanner`, button disabled | widget | `flutter test test/vote_screen_test.dart` | Wave 0 |
| FRNT-04 | `_ResultadosSection` renders `VoteCountItem` rows from stub service | widget | `flutter test test/resultados_section_test.dart` | Wave 0 |
| FRNT-05 | `DateTime.now().toUtc()` used at all comparison sites | static/grep | `grep -rn "DateTime.now()" frontend/lib/ \| grep -v ".toUtc()"` (should return 0 non-UTC hits after fix) | No test file needed — grep verify |

**Practical note on Flutter widget tests:** `flutter_test` is in `pubspec.yaml` dev_dependencies
already. The `test/` directory is empty — no widget tests have been written yet. Wave 0 must
create the test infrastructure. Given the project has no existing Flutter tests and the changes
are primarily integration-through-to-real-data (hard to unit-test without mocking GraphQL), the
validation strategy for this phase is:
1. **Grep check:** confirm `DateTime.now().toUtc()` at all date comparison sites (FRNT-05 is
   verifiable statically)
2. **Manual smoke test:** navigate from elections list → detail → vote → confirm → see success or
   AlreadyVoted state (FRNT-01, FRNT-02, FRNT-03 require backend)
3. **Widget tests:** if time permits, write a `VoteScreen` widget test with a mock `VoteService`
   to verify `_submitting` and `_alreadyVoted` state transitions without a backend

### Sampling Rate
- **Per task commit:** `flutter analyze` (static analysis)
- **Per wave merge:** `flutter test` (any unit tests present)
- **Phase gate:** `flutter analyze` clean + manual smoke test with running backend

### Wave 0 Gaps
- [ ] `frontend/test/vote_screen_test.dart` — widget tests for `_submitting` flag and `_alreadyVoted` banner
- [ ] `frontend/test/resultados_section_test.dart` — widget test for `_ResultadosSection` with stub data

*(If the project policy is manual testing only for this phase, these can be skipped — but
`flutter analyze` must pass.)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Auth already handled — `AuthStore.instance.isAuthenticated` read-only check in UI |
| V3 Session Management | No | JWT in memory via `AuthStore`; no new session logic |
| V4 Access Control | Yes | Admin check before showing `_ResultadosSection` content; backend enforces independently |
| V5 Input Validation | No | No free-text user input in this phase; all IDs are UUID strings from route args |
| V6 Cryptography | No | No cryptographic operations in Flutter for this phase |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Double-vote from rapid UI taps | Tampering | `_submitting` flag disables button during mutation; backend UNIQUE constraint is final guard |
| Admin results accessed by non-admin | Elevation of Privilege | `AuthStore.instance.isAdmin` check in `_ResultadosSection`; backend returns auth error for non-admin JWT |
| Route args null/wrong type crash | Tampering | `as VoteScreenArgs` hard cast — ensure all callers pass `VoteScreenArgs` before deploying |

---

## Project Constraints (from CLAUDE.md)

| Constraint | Impact on Phase 3 |
|-----------|-------------------|
| `VoteScreen` must receive `VoteScreenArgs(election, candidates)` — never hardcode candidates | Directly drives FRNT-01 implementation; `VoteScreen` constructor changes to `required this.args` |
| `AuditedCastVoteUseCase` must NOT log `candidateId` | Backend concern; Flutter must never send `voterId` in mutation (already in VoteService pattern) |
| Ballot secrecy | Flutter client does not display or log the candidate choice after successful vote (except in `_VotedBanner` for the voter's own UX) |
| Commit convention: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:` | All commits in Phase 3 use `feat:` for new behaviour, `fix:` for bug fixes, `refactor:` for screen rewrites |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Backend `castVote` mutation accepts `(electionId: String!, candidateId: String!)` without `voterId` from client — `voterId` extracted server-side from JWT | Pattern 2 (VoteService) | If backend requires `voterId` client-side, mutation will fail with "Missing argument" — fix: add `voterId` from `AuthStore` JWT decode |
| A2 | `AlreadyVoted` backend message is exactly `"Já votou nesta eleição."` | Pattern 3, Code Examples | If message differs, `CastVoteAlreadyVoted` will never be returned; voter sees generic `CastVoteFailure` instead — fix: update constant |
| A3 | Dart `(json['count'] as num).toInt()` is safe for `Long` values from backend on all platforms | Pattern 2 (VoteCountItem), Open Question 4 | On Dart web with values > 2^53, precision loss. Unlikely for vote counts in academic project |
| A4 | VOTAR button on `ActiveElectionsScreen` should redirect to `/elections/detail` rather than acquiring candidates inline | Architecture diagram, Pitfall 2 | If project requires single-tap voting from list, more code needed — but CLAUDE.md intent and VoteScreenArgs pattern implies detail-first |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed. (There are 4 assumptions — see above.)

---

## Sources

### Primary (HIGH confidence)
- Codebase grep + direct file reads — all existing Flutter files verified at exact line numbers
- `.planning/phases/02-backend-vertical-slice/02-04-PLAN.md` — confirmed GraphQL mutation signature, `AlreadyVoted` message string, VoteCountPayload type
- `.planning/phases/02-backend-vertical-slice/02-VERIFICATION.md` — confirmed Phase 2 is complete and verified
- `CLAUDE.md` — authoritative project constraints on `VoteScreenArgs`, ballot secrecy, route pattern

### Secondary (MEDIUM confidence)
- `frontend/pubspec.yaml` — confirmed no new packages needed; `flutter_test` already in dev_dependencies
- Dart `DateTime` UTC behavior documented in Dart SDK (standard behavior, well-established)

### Tertiary (LOW confidence)
- A1-A4 in Assumptions Log above — training knowledge about mutation argument inference from resolver code

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all existing, verified in pubspec.yaml
- Architecture: HIGH — derived directly from codebase read; no guesswork
- Pitfalls: HIGH for pitfalls 1/2/5/6 (directly observed in code); MEDIUM for pitfall 3/4 (inferred)
- Open questions: resolved with clear recommendations; only cosmetic/implementation-detail scope

**Research date:** 2026-05-22
**Valid until:** 2026-06-22 (stable Flutter/Dart APIs; backend contract locked post-Phase 2)
