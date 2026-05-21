# Architecture Patterns — Voting Module

**Domain:** Electronic voting module extension for Scala 3 Clean Architecture + Tagless Final project
**Researched:** 2026-05-21
**Confidence:** HIGH (all findings derived from direct codebase inspection)

---

## Recommended Architecture

The voting module is a new bounded context (`vote/`) that mirrors the existing `identity/` and `election/` contexts exactly. No new architectural patterns are needed — follow every convention already established.

### Complete Component Map with File Paths

```
backend/src/main/scala/pt/ipp/estg/elections/
│
├── vote/
│   ├── domain/
│   │   ├── Vote.scala                          ← aggregate root + value objects
│   │   ├── VoteRepository.scala                ← domain port trait
│   │   ├── VoteError.scala                     ← sealed error ADT
│   │   └── CastVoteLogic.scala                 ← pure EitherT pipeline (object)
│   │
│   ├── application/
│   │   ├── CastVoteAlg.scala                   ← use-case algebra trait
│   │   ├── CastVoteUseCase.scala               ← orchestrator (implements CastVoteAlg)
│   │   ├── GetVoteResultsAlg.scala             ← use-case algebra trait
│   │   └── GetVoteResultsUseCase.scala         ← orchestrator (implements GetVoteResultsAlg)
│   │
│   └── infrastructure/
│       └── DoobieVoteRepository.scala          ← implements VoteRepository[F] via Doobie
│
├── aop/
│   └── AuditedCastVoteUseCase.scala            ← decorator wrapping CastVoteAlg[F]
│
└── api/graphql/
    ├── ElectionContext.scala                   ← ADD: castVoteUseCase, getVoteResultsUseCase fields
    ├── MutationType.scala                      ← ADD: castVote mutation field
    ├── QueryType.scala                         ← ADD: electionResults query field
    └── schemas/
        └── VoteSchema.scala                    ← new: all vote-related Sangria types
```

---

## Component Boundaries

| Component | Responsibility | Depends On | Communicates With |
|-----------|---------------|------------|-------------------|
| `Vote` (domain entity) | Aggregate root: VoteId, VoterId, CandidateId, ElectionId, castedAt | Nothing (pure) | Used by all layers |
| `VoteRepository[F]` | Domain port: save, hasVoted, countByCandidate | Nothing (trait) | Implemented by DoobieVoteRepository |
| `VoteError` | Sealed ADT: AlreadyVoted, ElectionNotActive, CandidateNotInElection, VoterNotFound | Nothing | Used by CastVoteLogic, CastVoteAlg |
| `CastVoteLogic` | Pure EitherT pipeline: validate election active, validate candidate belongs, build Vote | `cats.Monad` only | Called by CastVoteUseCase |
| `CastVoteAlg[F]` | Use-case interface: `execute(voterId, electionId, candidateId): F[Either[VoteError, Vote]]` | Application layer | Implemented by CastVoteUseCase, AuditedCastVoteUseCase |
| `CastVoteUseCase` | Orchestrates: duplicate check, domain logic, persistence | VoteRepository[F], ElectionRepository[F], CandidateRepository[F] | Called via ElectionContext |
| `GetVoteResultsAlg[F]` | Use-case interface: `execute(electionId): F[List[CandidateVoteCount]]` | Application layer | Implemented by GetVoteResultsUseCase |
| `GetVoteResultsUseCase` | Delegates to VoteRepository.countByCandidate | VoteRepository[F] | Called via ElectionContext |
| `DoobieVoteRepository` | Implements VoteRepository[F] with SQL | Doobie, domain traits | Wired in Main.scala only |
| `AuditedCastVoteUseCase` | Decorator: wraps CastVoteAlg + records AuditEvent | CastVoteAlg[F], AuditLogAlg[F] | Wired in Main.scala only |
| `VoteSchema` | Sangria type definitions for vote payloads | Sangria | MutationType, QueryType |

---

## Detailed Design Decisions

### 1. CastVoteLogic — Pure Domain with Callback Pattern

Use the same callback pattern as `VoterRegistrationLogic`. The duplicate-vote check is a side-effectful concern (DB read), so it is injected as a callback parameter — it does not live inside the pure logic object.

```scala
// vote/domain/CastVoteLogic.scala
object CastVoteLogic {
  def castVote[F[_]: Monad](
    voterId:     VoterId,
    electionId:  ElectionId,
    candidateId: CandidateId,
    now:         Instant
  )(
    checkHasVoted:          (VoterId, ElectionId)              => F[Boolean],
    checkElectionActive:    (ElectionId, Instant)              => F[Option[Election]],
    checkCandidateInElection: (CandidateId, ElectionId)        => F[Boolean]
  ): F[Either[VoteError, Vote]] = {

    val pipeline = for {
      election <- EitherT(
                    checkElectionActive(electionId, now)
                      .map(_.toRight(ElectionNotActive: VoteError))
                  )
      inElection <- EitherT.liftF(checkCandidateInElection(candidateId, electionId))
      _          <- EitherT.cond[F](inElection, (), CandidateNotInElection: VoteError)
      alreadyVoted <- EitherT.liftF(checkHasVoted(voterId, electionId))
      _            <- EitherT.cond[F](!alreadyVoted, (), AlreadyVoted: VoteError)
    } yield Vote(VoteId(UUID.randomUUID()), voterId, candidateId, electionId, now)

    pipeline.value
  }
}
```

**Why callbacks over direct repo calls in logic:** The domain layer has zero imports from infrastructure. The logic object takes `F[_]: Monad` and pure function parameters — it never sees `VoteRepository[F]` directly. `CastVoteUseCase` assembles those callbacks from real repository calls, exactly as `RegisterVoterUseCase` passes `repository.checkExists` and `hasher.hash` into `VoterRegistrationLogic`.

### 2. VoteRepository — Explicit `hasVoted` Method + DB Unique Constraint

Use **both**: a `hasVoted(voterId, electionId): F[Boolean]` method on the repository **and** a DB-level `UNIQUE (voter_id, election_id)` constraint.

Reason for `hasVoted`: The domain logic pipeline must be able to return a typed `AlreadyVoted` error before attempting the insert, producing a clean `F[Either[VoteError, Vote]]` rather than a raw JDBC `PSQLException` that would need catching and re-mapping. `hasVoted` enables the `EitherT` pipeline to reject duplicates with a domain error.

Reason for the DB constraint: `hasVoted` followed by `save` is **not atomic**. Under concurrent load two requests for the same voter/election could both pass the `hasVoted` check and race to insert. The DB constraint is the final safety net; a constraint violation on insert should be caught in `DoobieVoteRepository.save` and translated to `F.raiseError` (or a known error type if needed at application level).

```scala
// vote/domain/VoteRepository.scala
trait VoteRepository[F[_]] {
  def save(vote: Vote): F[Unit]
  def hasVoted(voterId: VoterId, electionId: ElectionId): F[Boolean]
  def countByCandidate(electionId: ElectionId): F[List[CandidateVoteCount]]
}
```

The `countByCandidate` method returns a read-model list, aggregated by the DB with `GROUP BY candidate_id`. It does not return raw `Vote` rows.

### 3. CandidateVoteCount Result Type

Define as a simple case class in the domain layer (it is a read model, not an aggregate):

```scala
// vote/domain/CandidateVoteCount.scala  (can be in Vote.scala or separate)
case class CandidateVoteCount(
  candidateId:   CandidateId,
  candidateName: String,       // denormalised from candidates table via JOIN
  party:         Option[String],
  voteCount:     Int
)
```

`DoobieVoteRepository.countByCandidate` runs a single SQL query joining `votes` with `candidates` and using `COUNT(*) GROUP BY candidate_id`. Returning the candidate name from the DB avoids a second query or an N+1 candidate lookup at the application layer.

`GetVoteResultsAlg[F]` returns `F[List[CandidateVoteCount]]`. No `Either` needed: an empty list is a valid result (election has no votes yet), and infrastructure errors surface as `F` failures.

### 4. VoteError Sealed ADT

```scala
// vote/domain/VoteError.scala
sealed trait VoteError
case object AlreadyVoted            extends VoteError
case object ElectionNotActive       extends VoteError  // not found, not yet started, or already ended
case object CandidateNotInElection  extends VoteError
case object VoterNotAuthenticated   extends VoteError  // checked at GraphQL layer, not domain
```

`VoterNotAuthenticated` is checked in the GraphQL resolver before invoking the use case (same pattern as `authenticatedVoter.isEmpty` guard in `MutationType`), so it does not need to be a domain error. Include it in `VoteError` only if a policy decision is made to push auth checks into the use case — otherwise keep it as a resolver guard.

### 5. CastVoteUseCase — Orchestration

```scala
// vote/application/CastVoteUseCase.scala
class CastVoteUseCase[F[_]: Sync](
  voteRepo:      VoteRepository[F],
  electionRepo:  ElectionRepository[F],
  candidateRepo: CandidateRepository[F]
) extends CastVoteAlg[F] {

  def execute(
    voterId:     VoterId,
    electionId:  ElectionId,
    candidateId: CandidateId
  ): F[Either[VoteError, Vote]] = {
    val pipeline = for {
      now  <- EitherT.liftF(Sync[F].delay(Instant.now()))
      vote <- EitherT(
                CastVoteLogic.castVote[F](voterId, electionId, candidateId, now)(
                  checkHasVoted           = (v, e) => voteRepo.hasVoted(v, e),
                  checkElectionActive     = (e, t)  => electionRepo.findById(e)
                                              .map(_.filter(el => !t.isBefore(el.startDate) && t.isBefore(el.endDate))),
                  checkCandidateInElection = (c, e) => candidateRepo.findByElection(e)
                                              .map(_.exists(_.id == c))
                )
              )
      _    <- EitherT.liftF(voteRepo.save(vote))
    } yield vote
    pipeline.value
  }
}
```

`Sync[F]` is needed (same as `AddCandidateUseCase`) for `Instant.now()`. The use case assembles callbacks from repository calls — the domain logic object stays pure.

### 6. GraphQL Union Type for castVote

Follow the exact pattern of `CreateElectionPayload` and `AddCandidatePayload` in `ElectionSchema.scala`: a `UnionType` composed of a success `ObjectType` and an error `ObjectType`.

```scala
// api/graphql/schemas/VoteSchema.scala

case class VotePayload(voteId: String, electionId: String, candidateId: String, castedAt: String)
case class VoteErrorPayload(message: String)

val VotePayloadType: ObjectType[Unit, VotePayload] = ObjectType(
  "VotePayload",
  fields[Unit, VotePayload](
    Field("voteId",      StringType, resolve = _.value.voteId),
    Field("electionId",  StringType, resolve = _.value.electionId),
    Field("candidateId", StringType, resolve = _.value.candidateId),
    Field("castedAt",    StringType, resolve = _.value.castedAt)
  )
)

val VoteErrorPayloadType: ObjectType[Unit, VoteErrorPayload] = ObjectType(
  "VoteError",
  fields[Unit, VoteErrorPayload](
    Field("message", StringType, resolve = _.value.message)
  )
)

val CastVotePayloadType: UnionType[Unit] = UnionType(
  "CastVotePayload",
  types = List(VotePayloadType, VoteErrorPayloadType)
)

case class CandidateVoteCountPayload(
  candidateId: String,
  name:        String,
  party:       Option[String],
  voteCount:   Int
)

val CandidateVoteCountPayloadType: ObjectType[Unit, CandidateVoteCountPayload] = ObjectType(
  "CandidateVoteCount",
  fields[Unit, CandidateVoteCountPayload](
    Field("candidateId", StringType,             resolve = _.value.candidateId),
    Field("name",        StringType,             resolve = _.value.name),
    Field("party",       OptionType(StringType), resolve = _.value.party),
    Field("voteCount",   IntType,                resolve = _.value.voteCount)
  )
)
```

The `electionResults` query returns `ListType(CandidateVoteCountPayloadType)` — no union needed since there is no error case to distinguish; an empty list handles "no votes yet".

### 7. AuditedCastVoteUseCase Decorator

Mirrors `AuditedLoginUseCase` exactly: takes the wrapped `CastVoteAlg[F]` and an `AuditLogAlg[F]`, uses `flatTap` to record without altering the result.

```scala
// aop/AuditedCastVoteUseCase.scala
final class AuditedCastVoteUseCase[F[_]: FlatMap](
  target:   CastVoteAlg[F],
  auditLog: AuditLogAlg[F]
) extends CastVoteAlg[F] {

  def execute(
    voterId:     VoterId,
    electionId:  ElectionId,
    candidateId: CandidateId
  ): F[Either[VoteError, Vote]] =
    target.execute(voterId, electionId, candidateId).flatTap {
      case Right(vote) =>
        auditLog.record(AuditEvent(
          "CAST_VOTE",
          civilId = Some(voterId.value.toString),
          ip      = "n/a",                         // ip not in scope here; pass from context if needed
          success = true,
          reason  = None
        ))
      case Left(error) =>
        auditLog.record(AuditEvent(
          "CAST_VOTE",
          civilId = None,
          ip      = "n/a",
          success = false,
          reason  = Some(error.toString)
        ))
    }
}
```

**Note on `ip`:** `AuditedLoginUseCase` receives `ip` through the use-case `execute` signature. `CastVoteAlg.execute` does not carry `ip` by default since voting is not an auth event. Two options: (a) accept `ip` is not recorded for votes and pass `"n/a"` (simplest, consistent with current AuditEvent model), or (b) add `ip: String` to `CastVoteAlg.execute` and thread it through. Option (a) is recommended unless audit requirements specifically demand it.

`FlatMap` constraint (not `Sync`) — same as `AuditedLoginUseCase`. The decorator only needs sequential composition.

### 8. ElectionContext Extension

Add two fields to `ElectionContext`:

```scala
// api/graphql/ElectionContext.scala — updated
case class ElectionContext(
  // ... existing fields unchanged ...
  castVoteUseCase:       CastVoteAlg[IO],
  getVoteResultsUseCase: GetVoteResultsAlg[IO]
)
```

Both fields hold the top of the decorator chain (e.g., `AuditedCastVoteUseCase` for `castVoteUseCase`).

### 9. MutationType castVote Mutation

```scala
Field(
  name      = "castVote",
  fieldType = CastVotePayloadType,
  arguments = ElectionIdArg :: CandidateIdArg :: Nil,
  resolve   = ctx => {
    if (ctx.ctx.authenticatedVoter.isEmpty)
      Future.successful(VoteErrorPayload("Autenticação necessária."))
    else {
      val voter       = ctx.ctx.authenticatedVoter.get
      val electionId  = UUID.fromString(ctx.arg(ElectionIdArg))   // wrap in IO.fromTry
      val candidateId = UUID.fromString(ctx.arg(CandidateIdArg))

      ctx.ctx.dispatcher.unsafeToFuture(
        IO.fromTry(for {
          eid <- Try(UUID.fromString(ctx.arg(ElectionIdArg)))
          cid <- Try(UUID.fromString(ctx.arg(CandidateIdArg)))
        } yield (eid, cid)).flatMap { case (eid, cid) =>
          ctx.ctx.castVoteUseCase
            .execute(VoterId(voter.id), ElectionId(eid), CandidateId(cid))
            .map {
              case Right(vote)                   => VotePayload(vote.id.value.toString, vote.electionId.value.toString, vote.candidateId.value.toString, vote.castedAt.toString)
              case Left(AlreadyVoted)            => VoteErrorPayload("Este eleitor já votou nesta eleição.")
              case Left(ElectionNotActive)       => VoteErrorPayload("A eleição não está activa.")
              case Left(CandidateNotInElection)  => VoteErrorPayload("Candidato não pertence a esta eleição.")
            }
        }.handleError(_ => VoteErrorPayload("Pedido inválido."))
      )
    }
  }
)
```

`CandidateIdArg` is a new `Argument("candidateId", StringType)` in `MutationType`.

### 10. QueryType electionResults Query

```scala
Field(
  name      = "electionResults",
  fieldType = ListType(CandidateVoteCountPayloadType),
  arguments = ElectionIdArg :: Nil,
  resolve   = ctx =>
    ctx.ctx.dispatcher.unsafeToFuture(
      IO.fromTry(Try(UUID.fromString(ctx.arg(ElectionIdArg))))
        .flatMap { uuid =>
          ctx.ctx.getVoteResultsUseCase.execute(ElectionId(uuid)).map(
            _.map(r => CandidateVoteCountPayload(
              r.candidateId.value.toString, r.candidateName, r.party, r.voteCount
            ))
          )
        }
        .handleError(_ => List.empty)
    )
)
```

---

## Data Flow — castVote Mutation

```
Flutter VoteScreen
  │  castVote(electionId, candidateId) + Authorization: Bearer <jwt>
  │  HTTP POST /graphql
  ▼
Main.scala router
  │  extractBearerToken → tokenVerifier.verify → Option[AuthenticatedVoter]
  │  assemble ElectionContext (includes castVoteUseCase = AuditedCastVoteUseCase)
  ▼
MutationType.castVote field resolver
  │  guard: authenticatedVoter.isEmpty → VoteErrorPayload (short-circuit, no use-case call)
  │  parse UUID args via IO.fromTry
  │  dispatcher.unsafeToFuture(castVoteUseCase.execute(...))
  ▼
AuditedCastVoteUseCase.execute  [aop/AuditedCastVoteUseCase.scala]
  │  delegates to target.execute(...)
  │  flatTap: record AuditEvent to DoobieAuditLogRepository
  ▼
CastVoteUseCase.execute  [vote/application/CastVoteUseCase.scala]
  │  Sync[F].delay(Instant.now())
  │  CastVoteLogic.castVote[F](...)(callbacks)
  │    callback: electionRepo.findById → filter active window → Option[Election]
  │    callback: candidateRepo.findByElection → exists(_.id == candidateId) → Boolean
  │    callback: voteRepo.hasVoted(voterId, electionId) → Boolean
  │  [pure EitherT pipeline in CastVoteLogic]
  │    Left(ElectionNotActive)        if election not found / outside active window
  │    Left(CandidateNotInElection)   if candidate not in election
  │    Left(AlreadyVoted)             if duplicate
  │    Right(Vote(...))               on success
  │  voteRepo.save(vote) — only reached on Right
  ▼
DoobieVoteRepository  [vote/infrastructure/DoobieVoteRepository.scala]
  │  hasVoted: SELECT EXISTS(SELECT 1 FROM votes WHERE voter_id=? AND election_id=?)
  │  save:     INSERT INTO votes(id, voter_id, candidate_id, election_id, casted_at)
  │            DB unique constraint (voter_id, election_id) is final safety net
  ▼
PostgreSQL votes table  [V7__Create_votes_table.sql]
  │  UNIQUE (voter_id, election_id)  ← concurrent safety net
  ▼
Result propagates back:
  CastVoteUseCase → Either[VoteError, Vote]
  AuditedCastVoteUseCase → same Either (flatTap does not change it)
  MutationType → maps to VotePayload | VoteErrorPayload
  Sangria → serialises to JSON
  Flutter → sealed result → UI state update
```

---

## Data Flow — electionResults Query

```
Flutter ElectionDetailScreen (results tab)
  │  electionResults(electionId)  [no auth required — results are public]
  │  HTTP POST /graphql
  ▼
QueryType.electionResults field resolver
  │  parse UUID, dispatcher.unsafeToFuture(getVoteResultsUseCase.execute(...))
  ▼
GetVoteResultsUseCase.execute  [vote/application/GetVoteResultsUseCase.scala]
  │  delegates directly to voteRepo.countByCandidate(electionId)
  ▼
DoobieVoteRepository.countByCandidate
  │  SELECT c.id, c.name, c.party, COUNT(v.id) AS vote_count
  │  FROM candidates c LEFT JOIN votes v ON v.candidate_id = c.id
  │  WHERE c.election_id = ?
  │  GROUP BY c.id, c.name, c.party
  │  ORDER BY vote_count DESC
  ▼
F[List[CandidateVoteCount]] → mapped to List[CandidateVoteCountPayload] → JSON
```

---

## DB Migration

Add `V7__Create_votes_table.sql`:

```sql
CREATE TABLE IF NOT EXISTS votes (
    id           UUID        PRIMARY KEY,
    voter_id     UUID        NOT NULL REFERENCES voters(id),
    candidate_id UUID        NOT NULL REFERENCES candidates(id),
    election_id  UUID        NOT NULL REFERENCES elections(id),
    casted_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_one_vote_per_voter_per_election UNIQUE (voter_id, election_id)
);

CREATE INDEX IF NOT EXISTS idx_votes_election_id  ON votes (election_id);
CREATE INDEX IF NOT EXISTS idx_votes_candidate_id ON votes (candidate_id);
```

The unique constraint name `uq_one_vote_per_voter_per_election` makes the constraint's intent explicit in error messages and future migration scripts.

---

## Build Order (Dependency Graph)

Build in this order; each step can only begin once all arrows pointing to it are complete.

```
Step 1 — Domain (no deps, build first)
  vote/domain/VoteError.scala
  vote/domain/Vote.scala              (imports VoteError value objects)
  vote/domain/VoteRepository.scala    (imports Vote domain types)
  vote/domain/CastVoteLogic.scala     (imports Vote, VoteError; needs ElectionRepository types from election/domain)
  db/migration/V7__Create_votes_table.sql

Step 2 — Application (depends on domain + existing election/domain repos)
  vote/application/CastVoteAlg.scala          (depends on vote/domain)
  vote/application/GetVoteResultsAlg.scala    (depends on vote/domain)
  vote/application/CastVoteUseCase.scala      (depends on CastVoteAlg, VoteRepository, ElectionRepository, CandidateRepository)
  vote/application/GetVoteResultsUseCase.scala (depends on GetVoteResultsAlg, VoteRepository)

Step 3 — Infrastructure (depends on domain + Doobie)
  vote/infrastructure/DoobieVoteRepository.scala  (implements VoteRepository[F]; needs V7 migration to exist)

Step 4 — AOP (depends on application layer only)
  aop/AuditedCastVoteUseCase.scala    (depends on CastVoteAlg, AuditLogAlg — both already exist)

Step 5 — API (depends on all above)
  api/graphql/schemas/VoteSchema.scala         (new Sangria types; no backend deps)
  api/graphql/ElectionContext.scala            (add castVoteUseCase, getVoteResultsUseCase fields)
  api/graphql/MutationType.scala               (add castVote field; imports VoteSchema)
  api/graphql/QueryType.scala                  (add electionResults field; imports VoteSchema)

Step 6 — Wiring (depends on everything)
  Main.scala  (construct DoobieVoteRepository, CastVoteUseCase, GetVoteResultsUseCase,
               AuditedCastVoteUseCase; pass to ElectionContext constructor)
```

**Critical dependency note:** `CastVoteLogic` (domain) calls `checkElectionActive` and `checkCandidateInElection` callbacks. These callbacks are assembled in `CastVoteUseCase` using `ElectionRepository[F]` and `CandidateRepository[F]` — both already exist in `election/domain/`. The domain logic object itself only imports `cats.Monad`, `cats.data.EitherT`, and vote domain types. No circular dependency is introduced.

---

## Anti-Patterns to Avoid

### Calling VoteRepository directly from CastVoteLogic
**What it looks like:** Adding `repo: VoteRepository[F]` as a parameter to `CastVoteLogic.castVote`
**Why bad:** Domain layer acquires an infrastructure dependency; breaks the dependency inversion established by the callback pattern in `VoterRegistrationLogic` and `VoterLoginLogic`.
**Instead:** Pass `hasVoted` as `(VoterId, ElectionId) => F[Boolean]` callback; the use case wires it to `voteRepo.hasVoted`.

### Relying only on DB unique constraint for duplicate detection
**What it looks like:** No `hasVoted` method; `DoobieVoteRepository.save` catches `PSQLException` with code `23505` and re-throws a domain error.
**Why bad:** Infrastructure exception mapping bleeds into domain error semantics; the EitherT pipeline cannot short-circuit cleanly; error type is not exhaustively checked at compile time.
**Instead:** Use `hasVoted` for the clean typed path; keep the DB constraint as a concurrent safety net only.

### Embedding vote count aggregation in a separate VoteCountRepository
**What it looks like:** A new `VoteCountRepository[F]` trait with its own Doobie implementation.
**Why bad:** Unnecessary indirection; vote counts are a read concern of the same `votes` table. A single `VoteRepository[F]` with `countByCandidate` is sufficient and consistent with how `CandidateRepository` handles `findByElection`.
**Instead:** `countByCandidate` as a method on `VoteRepository[F]`.

### Adding a new Sangria `SchemaType` file for every result variant
**What it looks like:** `CandidateVoteCountSchema.scala`, `VoteResultSchema.scala` as separate files.
**Why bad:** Existing pattern is one schema file per bounded context (`ElectionSchema.scala`, `IdentitySchema.scala`). Fragmentation without benefit.
**Instead:** All vote-related Sangria types in `VoteSchema.scala`.

---

## Scalability Considerations

| Concern | Current scale | Mitigation needed |
|---------|--------------|-------------------|
| Concurrent duplicate votes | Race between `hasVoted` check and `save` | DB unique constraint already in V7 migration handles this |
| Vote count query performance | `LEFT JOIN votes ... GROUP BY candidate_id` on large elections | Index `idx_votes_candidate_id` in V7; acceptable for electoral scale |
| Real-time result updates | Polling from Flutter | Out of scope for MVP; GraphQL subscriptions would require Sangria subscription support and are not present in the current stack |
| Authentication on castVote | Checked in resolver only | Sufficient for current architecture; no middleware abstraction exists |

---

## Sources

All findings derived from direct inspection of:
- `backend/src/main/scala/pt/ipp/estg/elections/identity/domain/VoterRegistrationLogic.scala` — callback pattern evidence
- `backend/src/main/scala/pt/ipp/estg/elections/aop/AuditedLoginUseCase.scala` — decorator pattern evidence
- `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/ElectionContext.scala` — context structure
- `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/MutationType.scala` — union type and resolver pattern
- `backend/src/main/scala/pt/ipp/estg/elections/api/graphql/schemas/ElectionSchema.scala` — Sangria type pattern
- `backend/src/main/scala/pt/ipp/estg/elections/identity/application/RegisterVoterUseCase.scala` — use case orchestration pattern
- `backend/src/main/scala/pt/ipp/estg/elections/election/application/AddCandidateUseCase.scala` — Sync[F] + EitherT orchestration
- `backend/src/main/scala/pt/ipp/estg/elections/Main.scala` — wiring pattern
- `backend/src/main/resources/db/migration/V3–V4__*.sql` — existing migration conventions
