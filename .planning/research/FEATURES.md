# Feature Landscape: Vote-Casting Module

**Domain:** Electronic vote-casting for an authenticated electoral system
**Project:** VotoSeguro — TP2 PEDWM
**Researched:** 2026-05-21
**Confidence:** HIGH — based directly on existing codebase analysis and PROJECT.md requirements

---

## Table Stakes

Features that must exist or the vote-casting feature is broken/meaningless.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `castVote` GraphQL mutation | Core operation — without this nothing works | Medium | Args: `electionId: String!, candidateId: String!`; requires JWT in header |
| JWT authentication guard on castVote | A vote without identity is meaningless; already done for `createElection` | Low | Pattern already exists: `ctx.ctx.authenticatedVoter.isEmpty` check at mutation resolver level |
| Election-is-active validation | Votes outside the election window must be rejected | Low | Check `now >= election.startDate && now < election.endDate` using `Sync[F].delay(Instant.now())` — same pattern as `ListActiveElectionsUseCase` |
| Candidate-belongs-to-election validation | Prevents cross-election vote injection | Low | `candidateRepo.findById` then verify `candidate.electionId == electionId`; can reuse existing `CandidateRepository[F]` |
| One-vote-per-voter-per-election enforcement | Core electoral integrity guarantee | Medium | Two layers: DB UNIQUE constraint on `(voter_id, election_id)` in V7 migration + application-level pre-check before insert; DB constraint is the authoritative safety net |
| Typed error ADT (`VoteError`) | Consistent with existing `ElectionError`, `CandidateError`, `LoginError` patterns | Low | `sealed trait VoteError`: `ElectionNotFound`, `ElectionNotActive`, `CandidateNotFound`, `CandidateNotInElection`, `AlreadyVoted`, `NotAuthenticated` |
| `castVote` union return type | Existing pattern: `UnionType("CastVotePayload", List(VotePayloadType, VoteErrorPayloadType))` | Low | Success carries `voterId` (voter UUID) + `electionId` + `candidatedId` + `castedAt` timestamp |
| `V7__Create_votes_table.sql` Flyway migration | No persistence without schema | Low | `votes(id UUID PK, voter_id UUID FK voters, election_id UUID FK elections, candidate_id UUID FK candidates, created_at TIMESTAMPTZ)` with `UNIQUE(voter_id, election_id)` |
| `VoteRepository[F[_]]` domain trait | Clean Architecture requires domain-level port | Low | Methods: `save(vote: Vote): F[Unit]`, `existsByVoterAndElection(voterId, electionId): F[Boolean]` |
| `DoobieVoteRepository` infrastructure impl | Concrete persistence | Low | Follows identical pattern to `DoobieCandidateRepository` |
| `CastVoteAlg[F[_]]` use-case algebra trait | Required for decorator wrapping and testability | Low | `def execute(voterId: VoterId, electionId: UUID, candidateId: UUID): F[Either[VoteError, Vote]]` |
| `CastVoteUseCase` application class | Orchestrates domain logic + repo calls | Medium | EitherT pipeline: auth check → find election → active check → find candidate → membership check → duplicate check → save |
| `AuditedCastVoteUseCase` AOP decorator | Consistency with `AuditedLoginUseCase`; audit_log already has `event_type` column for "VOTE_CAST" | Low | Wraps `CastVoteAlg[F]`; records `AuditEvent("VOTE_CAST", Some(voter.civilId.value), ip, success, reason)` |
| `ElectionContext` extended with `castVoteUseCase` | Context must carry the new use case for resolver access | Low | Add `castVoteUseCase: CastVoteAlg[IO]` field; wire in `Main.scala` |
| VoteScreen wired to real candidates from route args | Current screen uses hardcoded `_Candidate` list; `ElectionDetailScreen` passes only `ElectionItem` to route | Medium | Route args must change from `ElectionItem` to a `VoteScreenArgs(election: ElectionItem, candidates: List<CandidateItem>)` class; VoteScreen reads `ModalRoute.settings.arguments as VoteScreenArgs` |
| `VoteService` (Flutter) with `castVote` method | Front-end needs to call the mutation with JWT header | Low | Pattern: `sealed class CastVoteResult {}` with `CastVoteSuccess` / `CastVoteFailure`; mirrors `CreateElectionResult` pattern in `election_service.dart` |
| Post-vote UI state (voted banner, button disabled) | VoteScreen already has `_voted` bool and `_VotedBanner` widget — just needs to be wired to real outcome | Low | Already implemented visually; change `setState(() => _voted = true)` to only fire on confirmed `CastVoteSuccess` |
| `electionResults` admin-only GraphQL query | Admin needs to see vote counts; already in Active requirements | Medium | Returns `List[CandidateResult]` with `candidateId`, `candidateName`, `voteCount`; admin auth guard mirrors `createElection` check |
| `ElectionResultsAlg[F[_]]` + use case | Application layer for results query | Low | `execute(electionId: UUID): F[Either[VoteError, List[CandidateVoteCount]]]` |
| Admin results UI (Flutter) | "Tab Resultados" currently shows placeholder | Medium | Needs real `VoteService.electionResults(electionId)` call; render bar/list of candidates with counts |

---

## Differentiators

Features that improve the product but are not blocking for a correct v1.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Election time remaining display (live) | VoteScreen `_StatusBar` already shows hardcoded "Encerra em 2h 45m"; make it real | Low | Compute `election.endDate.difference(DateTime.now())` from passed `ElectionItem`; no backend call needed |
| Disable vote button + show message if election ended/not started | Prevents users from attempting a doomed mutation call | Low | Frontend-only: compare `DateTime.now()` with `ElectionItem.startDate`/`endDate` before showing VOTAR button |
| "Already voted" graceful state in VoteScreen | Voter lands on VoteScreen for an election they already voted in; show informational state instead of form | Medium | Requires either: (a) query endpoint `hasVoted(electionId): Boolean` (admin-only in current design), or (b) catch `AlreadyVoted` error on submit and update state; option (b) is much simpler |
| Vote count total alongside per-candidate counts in `electionResults` | Admin sees both per-candidate counts and total participation | Low | Aggregate in use-case or SQL; add `totalVotes: Int` field to `ElectionResultsPayload` |
| Percentage breakdown in results | Bar chart is more readable than raw counts alone | Low | Computed client-side: `(voteCount / totalVotes * 100)`; no backend change |
| Candidate `partyColor` / `acronym` fields | VoteScreen hardcodes party colors and acronyms; these are not in the `candidates` table | Medium | Would require schema change (V8 migration) to add `acronym VARCHAR(20)`; party color would remain client-side derived. Out of scope for TP2 unless schema extension is approved. |

---

## Anti-Features

Things to explicitly NOT build in v1.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Cryptographic ballot anonymisation | PROJECT.md explicitly lists "Boletim cifrado/anónimo criptograficamente" as Out of Scope. UI mentions "cifrado" but this is cosmetic text only. Implementing real crypto (Paillier, blind signatures) is a full research project. | Leave the footer text as-is; it is editorial copy, not a specification |
| WebSocket push for live results | PROJECT.md calls this "V2"; the infrastructure for audit streaming exists but is not connected to votes. Adding Sangria subscriptions + cats-effect streaming now would be large scope. | Admin refreshes the results tab manually; polling is acceptable for TP2 |
| Voter-visible results before election ends | PROJECT.md states "Resultados visíveis a não-admins durante a eleição — decisão do produto; apenas admin vê em tempo real". Exposing partial results creates strategic voting behaviour. | `electionResults` query must be admin-only; non-admin calls return `NotAuthenticated` error |
| Vote modification or retraction | "Remoção ou alteração de votos — voto é irreversível por design". The UI already shows "Esta acção é irreversível." Adding an undo path contradicts the core value proposition. | The `UNIQUE(voter_id, election_id)` constraint enforces this at DB level; no update/delete needed on votes table |
| NUT3 region-scoped election eligibility | PROJECT.md: "Ligação entre NUT3 region do eleitor e eleições regionais — fora do âmbito do TP2". The `Nut3Region` enum exists on `AuthenticatedVoter` but election filtering by region would require schema changes and product decisions not yet made. | All authenticated voters can vote in any active election |
| IP address blacklisting or rate limiting | Adds significant infrastructure complexity (Redis, middleware). For a university project with one vote allowed per voter per election, the UNIQUE constraint is sufficient. | UNIQUE constraint + application pre-check is the concurrency protection strategy |
| Separate vote confirmation email / receipt token | Requires SMTP integration, token storage, and expiry logic — entirely new infrastructure surface. | The confirmation dialog in the UI ("Esta acção é irreversível — CONFIRMAR") serves as the confirmation UX |
| Blind voter ID in votes table | True ballot secrecy would use a voter token that cannot be linked back to the voter. Not required for TP2; `voter_id` FK is fine. | Store `voter_id` directly in `votes` table; the system is not claiming cryptographic anonymity |
| Admin CRUD on vote records | Deleting or modifying individual votes is an electoral integrity violation and contradicts the immutability design. | No update/delete queries on `votes` table; `VoteRepository` exposes `save` and `existsByVoterAndElection` only |

---

## Feature Dependencies

```
V7 Flyway migration (votes table)
  → VoteRepository[F] domain trait
    → DoobieVoteRepository (infrastructure)
      → CastVoteUseCase (application)
        → AuditedCastVoteUseCase (AOP decorator)
          → ElectionContext (add castVoteUseCase field)
            → Main.scala wiring
              → MutationType.castVote resolver (backend done)

CastVoteUseCase
  → ElectionRepository[F].findById  (already exists)
  → CandidateRepository[F].findById  (already exists — need to add this method if not present)
  → VoteRepository[F].existsByVoterAndElection
  → VoteRepository[F].save

MutationType.castVote resolver (backend done)
  → VoteService.castVote (Flutter)
    → VoteScreenArgs (new route args class)
      → ElectionDetailScreen route push (change arguments from ElectionItem to VoteScreenArgs)
        → VoteScreen reads real candidates from args
          → VoteScreen wires _confirmVote to VoteService.castVote
            → Post-vote UI state driven by CastVoteResult (frontend done)

ElectionResultsUseCase
  → VoteRepository[F].countByElectionGroupedByCandidate  (new repo method)
    → DoobieVoteRepository (SQL: GROUP BY candidate_id + JOIN candidates)
      → ElectionContext (add electionResultsUseCase field)
        → QueryType.electionResults resolver
          → VoteService.electionResults (Flutter)
            → Admin results tab in Flutter
```

---

## Validation Rules: Before Accepting a Vote

All checks must pass in this order. Each failed check returns a typed `VoteError` case object, not a generic string.

| Check | Error Case | Implementation Layer | Notes |
|-------|------------|----------------------|-------|
| JWT present and valid | `NotAuthenticated` | Resolver (before use-case call) | Same pattern as `createElection`: `if (ctx.ctx.authenticatedVoter.isEmpty)` |
| `electionId` is a valid UUID | `ElectionNotFound` (parse failure) | Resolver (IO.fromTry) | Same pattern as `addCandidate` UUID parsing |
| Election record exists in DB | `ElectionNotFound` | Use case, `ElectionRepository.findById` | |
| Election is currently active (`now >= startDate && now < endDate`) | `ElectionNotActive` | Use case, domain logic | `Sync[F].delay(Instant.now())` — same as `ListActiveElectionsUseCase` |
| `candidateId` is a valid UUID | `CandidateNotFound` (parse failure) | Resolver | |
| Candidate record exists in DB | `CandidateNotFound` | Use case, `CandidateRepository.findById` |  |
| Candidate belongs to the specified election | `CandidateNotInElection` | Use case: `candidate.electionId == ElectionId(electionId)` | Pure check, no extra query |
| Voter has not already voted in this election | `AlreadyVoted` | Use case, `VoteRepository.existsByVoterAndElection` | Application-level pre-check; DB UNIQUE constraint is the authoritative backstop for races |

The DB `UNIQUE(voter_id, election_id)` constraint on `votes` handles concurrent duplicate submissions that slip past the application pre-check. The application must handle the resulting `PSQLException` (unique_violation, code 23505) and map it to `AlreadyVoted`.

---

## `castVote` Mutation: Return Shape

Following the existing union-type pattern (`CreateElectionPayload`, `AddCandidatePayload`):

```graphql
# Success
type VotePayload {
  voterId:     String!   # voter UUID (confirms whose vote was recorded)
  electionId:  String!
  candidateId: String!
  castedAt:    String!   # ISO-8601 timestamp
}

# Error
type VoteError {
  message: String!   # human-readable Portuguese message
}

# Union
union CastVotePayload = VotePayload | VoteError
```

Typed errors map to Portuguese messages following the existing convention:
- `NotAuthenticated` → "Autenticação necessária."
- `ElectionNotFound` → "Eleição não encontrada."
- `ElectionNotActive` → "A eleição não está activa."
- `CandidateNotFound` → "Candidato não encontrado."
- `CandidateNotInElection` → "O candidato não pertence a esta eleição."
- `AlreadyVoted` → "Já votou nesta eleição."

The `castedAt` field is important: it lets the frontend display the vote timestamp in the confirmed-vote banner without requiring a subsequent query.

---

## `electionResults` Query: Return Shape

Admin-only. Returns per-candidate vote counts for one election.

```graphql
query {
  electionResults(electionId: String!): ElectionResultsPayload | ElectionResultsError
}

type CandidateResultItem {
  candidateId:   String!
  candidateName: String!
  candidateNumber: Int!
  party:         String       # nullable, same as Candidate
  voteCount:     Int!
}

type ElectionResultsPayload {
  electionId:  String!
  totalVotes:  Int!
  candidates:  [CandidateResultItem!]!
}

type ElectionResultsError {
  message: String!
}
```

The query is a SQL `SELECT c.id, c.name, c.number, c.party, COUNT(v.id) AS vote_count FROM candidates c LEFT JOIN votes v ON v.candidate_id = c.id WHERE c.election_id = $electionId GROUP BY c.id`. `LEFT JOIN` ensures candidates with zero votes still appear (important for real-time admin view).

Admin auth guard: same inline check `ctx.ctx.authenticatedVoter.exists(_.isAdmin)` used in `createElection` and `addCandidate`.

---

## Audit Trail Requirements

Following `AuditedLoginUseCase` as the reference pattern:

| Event | `event_type` | `civil_id` | `success` | `reason` |
|-------|--------------|-----------|-----------|----------|
| Successful vote | `"VOTE_CAST"` | voter's civilId | `true` | `None` |
| Failed vote (any VoteError) | `"VOTE_CAST"` | voter's civilId (or `None` if not authenticated) | `false` | `Some(error.toString)` |

Implementation: `AuditedCastVoteUseCase[F[_]: FlatMap]` wraps `CastVoteAlg[F]` using `flatTap` — identical structure to `AuditedLoginUseCase`. The decorator receives `AuditLogAlg[F]` (already exists as `DoobieAuditLogRepository`). No new infrastructure needed for audit storage; the existing `audit_log` table and `event_type VARCHAR(50)` column accommodate `"VOTE_CAST"`.

The IP address is available in `ElectionContext.requestIp` and must be threaded through to the audit decorator (same as login audit). The `castVote` resolver extracts it from `ctx.ctx.requestIp`.

---

## MVP Recommendation

Implement in this order (each step is independently deployable and testable):

1. **V7 migration + `VoteRepository[F]` + `DoobieVoteRepository`** — unblocks everything; schema-first
2. **`CastVoteUseCase` + `VoteError` ADT + `CastVoteAlg[F]`** — core business logic
3. **`AuditedCastVoteUseCase`** — cross-cutting concern; wire before exposing mutation
4. **`MutationType.castVote` + `CastVotePayloadType` in `ElectionSchema`** — backend surface complete
5. **`ElectionContext` + `Main.scala` wiring** — integrate into request pipeline
6. **`VoteScreenArgs` + `ElectionDetailScreen` route change + `VoteScreen` reads real candidates** — Flutter wiring
7. **`VoteService.castVote` + post-vote UI state** — Flutter mutation + feedback
8. **`ElectionResultsUseCase` + `QueryType.electionResults`** — admin query
9. **Admin results tab in Flutter** — closes the Active requirements list

Defer to differentiators (not blocking): live countdown in VoteScreen, "already voted" proactive state, percentage breakdown in results.

---

## Sources

- Codebase direct analysis (HIGH confidence): `MutationType.scala`, `ElectionContext.scala`, `AuditedLoginUseCase.scala`, `AuditEvent.scala`, `DoobieAuditLogRepository.scala`, `AddCandidateUseCase.scala`, `ElectionSchema.scala`, `Main.scala`, all Flyway migrations V1–V6
- `PROJECT.md` requirements and Out of Scope declarations (HIGH confidence)
- `.planning/codebase/ARCHITECTURE.md` (HIGH confidence)
- Existing Flutter service patterns: `election_service.dart`, `vote_screen.dart`, `election_detail_screen.dart`
