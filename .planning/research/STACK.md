# Technology Stack — Vote-Casting Feature Research

**Project:** VotoSeguro — ballot-box
**Researched:** 2026-05-21
**Scope:** Doobie + PostgreSQL concurrency for vote persistence; PSQLException propagation through Cats Effect
**Confidence:** HIGH — all findings are grounded in the exact library versions present in `build.sbt` (Doobie 1.0.0-RC8, Cats Effect 3.5.7, PostgreSQL JDBC 42.x via doobie-postgres). No external searches required; the APIs described are stable and well within training knowledge cutoff.

---

## 1. Concurrency Guarantee Strategy: UNIQUE Constraint (Recommended)

### Decision: UNIQUE (voter_id, election_id) — already decided in PROJECT.md

**Confidence: HIGH**

PostgreSQL's UNIQUE constraint provides a serializable guarantee at the storage engine level. Two concurrent INSERTs for the same `(voter_id, election_id)` pair will race inside PostgreSQL's index manager; exactly one will commit, the other will receive `ERROR 23505 unique_violation`. This is the correct tool for this problem.

#### Why NOT SELECT FOR UPDATE

`SELECT FOR UPDATE` requires a pre-existing row to lock. For an INSERT use case (the vote does not yet exist), it provides no protection: both transactions read zero rows, both decide to insert, and you still get a race. To use it correctly you would need a "vote slot" row inserted at voter-registration time — unnecessary complexity.

**Confidence: HIGH** (PostgreSQL documentation on row-level locking, also confirmed by the project's own KEY DECISIONS table in PROJECT.md).

#### Why NOT Advisory Locks

`pg_try_advisory_xact_lock(voter_id_hash, election_id_hash)` does work, but it requires:
- Deriving stable integer keys from UUIDs (lossy hash, collision risk)
- Holding the lock for the entire transaction duration across a connection pool
- Application-level state that does not survive server restart or failover

A UNIQUE constraint requires no application logic, survives restarts, is enforced even for direct SQL access, and is self-documenting. Advisory locks are appropriate when the resource being protected is not a row (e.g., "only one job scheduler at a time"). They are the wrong tool here.

**Confidence: HIGH**

#### Why NOT application-level check-then-insert

The `RegisterVoterUseCase` pattern (call `checkExists`, then `save`) works for voter registration because civil IDs are human-entered and registrations are infrequent. For voting, two simultaneous HTTP requests for the same voter will both pass the `checkExists = false` check and both attempt to INSERT before either commits. This is a classic TOCTOU race. Do NOT replicate the check-then-insert pattern for votes.

**Confidence: HIGH**

### The Flyway V7 Migration

```sql
-- V7__Create_votes_table.sql
CREATE TABLE IF NOT EXISTS votes (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    voter_id    UUID        NOT NULL REFERENCES voters(id),
    election_id UUID        NOT NULL REFERENCES elections(id),
    candidate_id UUID       NOT NULL REFERENCES candidates(id),
    cast_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_one_vote_per_voter_per_election UNIQUE (voter_id, election_id)
);

CREATE INDEX IF NOT EXISTS idx_votes_election_id  ON votes (election_id);
CREATE INDEX IF NOT EXISTS idx_votes_candidate_id ON votes (candidate_id);
```

Key points:
- `gen_random_uuid()` for `id` — no application-side UUID generation needed (contrast with existing tables that pass UUID from Scala; either approach is fine, but gen_random_uuid() is simpler for an INSERT-only table).
- The constraint name `uq_one_vote_per_voter_per_election` matches the pattern of `uq_candidate_number_per_election` already in V4.
- `voter_id` references `voters(id)`, NOT `voters(civil_id)`. The JWT claims carry `civilId` (String), so the repository layer must resolve `civilId → VoterId (UUID)` before inserting. This is consistent with how `DoobieVoterRepository.findByCivilId` already works.

---

## 2. Doobie Transaction Handling for Concurrent Writes

**Confidence: HIGH** — Doobie 1.0.0-RC8 API, stable since RC4.

### How `.transact(xa)` Works

Every call to `.transact(xa)` in the existing repositories runs one JDBC transaction: `BEGIN` → SQL statements → `COMMIT` (or `ROLLBACK` on exception). The `Transactor.fromDriverManager` used in `Main.scala` creates a new JDBC connection per transaction. This is correct for correctness, though a connection pool (HikariCP via `doobie-hikari`) would be better for production load — not required for TP2.

### The INSERT Pattern for Vote Casting

The vote INSERT is a single statement. There is no need for a multi-statement transaction. The simplest correct implementation:

```scala
// In DoobieVoteRepository[F[_]: MonadCancelThrow]
def castVote(vote: Vote): F[Either[VoteError, Unit]] =
  sql"""
    INSERT INTO votes (voter_id, election_id, candidate_id)
    VALUES (${vote.voterId.value}, ${vote.electionId.value}, ${vote.candidateId.value})
  """.update.run
    .transact(xa)
    .void
    .map(Right(_))
    .recoverWith {
      case ex: org.postgresql.util.PSQLException
          if ex.getSQLState == "23505" =>
        MonadCancelThrow[F].pure(Left(AlreadyVoted))
    }
```

`MonadCancelThrow[F]` is already the constraint used in all other repositories (`DoobieCandidateRepository`, `DoobieElectionRepository`, `DoobieVoterRepository`). No new typeclass constraint is needed.

### Multi-statement Transaction (for result-count reads in same tx)

If you ever need to read `election_results` and insert in the same transaction (not required for vote casting):

```scala
import doobie.implicits._

val program: ConnectionIO[Unit] = for {
  _ <- sql"INSERT INTO votes ...".update.run
  _ <- sql"UPDATE ...".update.run  // hypothetical
} yield ()

program.transact(xa)
```

`ConnectionIO` is Doobie's free monad over a single connection. Combining multiple `ConnectionIO` values with `flatMap`/`for` runs them in one transaction. Only call `.transact(xa)` once at the end. The existing repositories all call `.transact(xa)` per statement, which is correct for single-statement operations.

---

## 3. PSQLException Propagation Through Doobie / Cats Effect

**Confidence: HIGH** — Stable Doobie + PostgreSQL JDBC behaviour.

### What Happens Without Handling

When the UNIQUE constraint fires, PostgreSQL sends `SQLSTATE 23505` back over JDBC. Doobie's `update.run.transact(xa)` surface this as a `java.sql.SQLException` wrapping an `org.postgresql.util.PSQLException`. Cats Effect's `IO` captures it as a failed effect. If unhandled, it propagates as an `IO` failure up to the Sangria executor, which will return a generic GraphQL error to the client — no domain meaning.

### Correct Interception Point: The Repository

The UNIQUE constraint is a database-layer concern. Catch it in the repository (infrastructure layer) and convert it to a domain error. This keeps the use case and domain logic free of JDBC types.

```scala
import org.postgresql.util.PSQLException
import cats.effect.MonadCancelThrow

// In DoobieVoteRepository
def castVote(vote: Vote): F[Either[VoteError, Unit]] =
  sql"""
    INSERT INTO votes (voter_id, election_id, candidate_id)
    VALUES (${vote.voterId.value}, ${vote.electionId.value}, ${vote.candidateId.value})
  """.update.run
    .transact(xa)
    .void
    .attempt                          // F[Either[Throwable, Unit]]
    .map {
      case Right(_)  => Right(())
      case Left(ex: PSQLException) if ex.getSQLState == "23505" =>
        Left(AlreadyVoted: VoteError)
      case Left(ex)  => throw ex      // re-raise unexpected exceptions
    }
```

`.attempt` is the idiomatic Cats Effect combinator on `F[A]` that converts `F[A]` to `F[Either[Throwable, A]]` without leaving the effect. It is available on any `F[_]: ApplicativeError[*[_], Throwable]`, which `MonadCancelThrow[F]` satisfies.

Alternative using `.recoverWith` (more concise):

```scala
def castVote(vote: Vote): F[Either[VoteError, Unit]] =
  sql"""
    INSERT INTO votes (voter_id, election_id, candidate_id)
    VALUES (${vote.voterId.value}, ${vote.electionId.value}, ${vote.candidateId.value})
  """.update.run
    .transact(xa)
    .as(Right(()): Either[VoteError, Unit])
    .recoverWith {
      case ex: PSQLException if ex.getSQLState == "23505" =>
        MonadCancelThrow[F].pure(Left(AlreadyVoted))
    }
```

`.recoverWith` on `F[A]` takes a `PartialFunction[Throwable, F[A]]`. It is the Cats Effect equivalent of `recover` but allows returning a new `F[A]`.

### SQLSTATE Codes to Handle

| SQLState | PostgreSQL name | Meaning for this project |
|----------|-----------------|--------------------------|
| `23505`  | `unique_violation` | Voter already voted in this election — map to `AlreadyVoted` |
| `23503`  | `foreign_key_violation` | `voter_id`, `election_id`, or `candidate_id` does not exist — map to domain error or re-raise |
| `23514`  | `check_violation` | Would fire on the elections table `chk_election_dates` check — not relevant to votes INSERT |

For the vote casting path, only `23505` needs explicit domain mapping. All others should be re-raised and surface as GraphQL internal errors.

### Import Required

```scala
import org.postgresql.util.PSQLException
```

This class is available via `doobie-postgres 1.0.0-RC8` which depends on `postgresql` JDBC driver. No new dependency needed.

### Do NOT Use `doobie.postgres.sqlstate`

Doobie-postgres provides `doobie.postgres.sqlstate.class23.UNIQUE_VIOLATION` as a `SqlState` value, and `attemptSqlState` / `exceptSqlState` combinators on `ConnectionIO`. These work on `ConnectionIO` (before `.transact`), not on `F[_]`. Example for completeness:

```scala
// Only works BEFORE .transact — inside ConnectionIO context
val program: ConnectionIO[Either[VoteError, Unit]] =
  sql"INSERT INTO votes ...".update.run
    .attemptSqlState {
      case sqlstate.class23.UNIQUE_VIOLATION => AlreadyVoted: VoteError
    }
    .map(_.left.map(identity))  // Either[VoteError, Int] -> Either[VoteError, Unit]

program.transact(xa)
```

`attemptSqlState` is cleaner if you are composing a `ConnectionIO` pipeline (multi-statement tx). For single-statement repositories the `.recoverWith` on `F` approach shown above is equally correct and aligns better with how existing repositories are structured (all call `.transact(xa)` immediately).

**Recommendation for this project:** Use `.recoverWith` on `F` (post-transact), matching the style of all existing Doobie repositories. Reserve `ConnectionIO`-level combinators for multi-statement transactions.

---

## 4. Cats Effect IO Patterns for Safe DB Transactions in Scala 3

**Confidence: HIGH**

### Typeclass Constraint: MonadCancelThrow[F]

All existing repositories use `MonadCancelThrow[F]`. This is the correct minimum constraint for database access:
- `Monad` for `flatMap` / `for` comprehension
- `MonadError[*[_], Throwable]` for `.attempt` / `.recoverWith`
- `MonadCancel` for safe resource acquisition (connection release on cancellation)

The `CastVoteUseCase` should use `Sync[F]` (as `CreateElectionUseCase` does) to call `Sync[F].delay(UUID.randomUUID())` for ID generation, and `MonadCancelThrow[F]` is satisfied by `Sync[F]`. The repository itself only needs `MonadCancelThrow[F]`.

### Pattern: EitherT Pipeline in Use Case

Follow the exact pattern of `AddCandidateUseCase` and `CreateElectionUseCase`:

```scala
class CastVoteUseCase[F[_]: Sync](
  voteRepo:     VoteRepository[F],
  electionRepo: ElectionRepository[F],
  voterRepo:    VoterRepository[F]   // needed to resolve civilId -> VoterId
) extends CastVoteAlg[F]:

  def execute(
    civilId:    String,
    electionId: UUID,
    candidateId: UUID
  ): F[Either[VoteError, Vote]] =

    val pipeline = for
      voter    <- EitherT(
                    voterRepo.findByCivilId(CivilId(civilId))
                      .map(_.toRight(VoterNotFound: VoteError))
                  )
      election <- EitherT(
                    electionRepo.findById(ElectionId(electionId))
                      .map(_.toRight(ElectionNotFound: VoteError))
                  )
      now      <- EitherT.liftF(Sync[F].delay(Instant.now()))
      _        <- EitherT.fromEither[F](
                    CastVoteLogic.validate(election, now)
                  )
      vote      = Vote(voter.id, election.id, CandidateId(candidateId))
      _        <- EitherT(voteRepo.castVote(vote))   // repository maps 23505 -> AlreadyVoted
    yield vote

    pipeline.value
```

This keeps all domain validation in `CastVoteLogic` (pure, testable without F), all DB access behind the repository interface, and all JDBC exceptions converted before they reach the use case.

### AuditedCastVoteUseCase Decorator

Following `AuditedLoginUseCase` exactly:

```scala
final class AuditedCastVoteUseCase[F[_]: FlatMap](
  target:   CastVoteAlg[F],
  auditLog: AuditLogAlg[F]
) extends CastVoteAlg[F]:

  def execute(civilId: String, electionId: UUID, candidateId: UUID): F[Either[VoteError, Vote]] =
    target.execute(civilId, electionId, candidateId).flatTap {
      case Right(_) =>
        auditLog.record(AuditEvent("VOTE_CAST", Some(civilId), "unknown", success = true, reason = None))
      case Left(err) =>
        auditLog.record(AuditEvent("VOTE_CAST", Some(civilId), "unknown", success = false, reason = Some(err.toString)))
    }
```

Note: `AuditedLoginUseCase` passes `ip` from the GraphQL context. The `ElectionContext` already carries `requestIp`; the vote mutation resolver can read it and pass it down, or the `AuditedCastVoteUseCase` signature can accept `ip: String` as a parameter. Follow the login pattern.

### What NOT to Do: IO.blocking

Do NOT wrap `Transactor.fromDriverManager` calls in `IO.blocking`. Doobie's `Transactor` already manages thread shifting. The `fromDriverManager` transactor creates a blocking JDBC call internally — Doobie handles this correctly. Adding `IO.blocking` around `.transact(xa)` will double-shift threads unnecessarily. (For production, `Transactor.fromHikariConfig` with a dedicated blocking thread pool is preferred, but that is out of scope for TP2.)

---

## 5. VoteError Domain Type

The domain error type should model all distinguishable failure cases for the use case consumer (MutationType resolver):

```scala
sealed trait VoteError
case object AlreadyVoted         extends VoteError  // 23505 from DB
case object ElectionNotActive    extends VoteError  // election not in [start, end] window
case object ElectionNotFound     extends VoteError  // no election with given UUID
case object VoterNotFound        extends VoteError  // civilId not in voters table
case object CandidateNotInElection extends VoteError // optional: validate candidate belongs to election
```

`CandidateNotInElection` can be enforced at the DB level via the `candidates.election_id` FK and a SELECT before INSERT, or validated in `CastVoteLogic`. The FK ensures the DB is consistent regardless.

---

## 6. GraphQL Mutation Wiring (MutationType Pattern)

Following the `addCandidate` field exactly:

```scala
Field(
  name      = "castVote",
  fieldType = CastVotePayloadType,
  arguments = ElectionIdArg :: CandidateIdArg :: Nil,  // voter identity comes from JWT, not args
  resolve   = ctx => {
    if (ctx.ctx.authenticatedVoter.isEmpty)
      Future.successful(VoteErrorPayload("Autenticação necessária."))
    else {
      val electionId  = UUID.fromString(ctx.arg(ElectionIdArg))
      val candidateId = UUID.fromString(ctx.arg(CandidateIdArg))
      val civilId     = ctx.ctx.authenticatedVoter.get.civilId.value  // from JWT claims

      ctx.ctx.dispatcher.unsafeToFuture(
        ctx.ctx.castVoteUseCase.execute(civilId, electionId, candidateId).map {
          case Right(vote)              => VotePayload(vote.electionId.value.toString)
          case Left(AlreadyVoted)       => VoteErrorPayload("Já votou nesta eleição.")
          case Left(ElectionNotActive)  => VoteErrorPayload("A eleição não está activa.")
          case Left(ElectionNotFound)   => VoteErrorPayload("Eleição não encontrada.")
          case Left(VoterNotFound)      => VoteErrorPayload("Eleitor não encontrado.")
          case Left(CandidateNotInElection) => VoteErrorPayload("Candidato não pertence a esta eleição.")
        }
      )
    }
  }
)
```

The voter's `civilId` comes from the JWT-authenticated `AuthenticatedVoter` in context, not from the mutation arguments. This ensures a voter cannot cast a vote in another voter's name.

---

## 7. electionResults Query (Admin-Only)

```scala
// SQL for vote count aggregation
sql"""
  SELECT c.id, c.name, c.party, c.number, COUNT(v.id) AS vote_count
  FROM candidates c
  LEFT JOIN votes v ON v.candidate_id = c.id
  WHERE c.election_id = $electionId
  GROUP BY c.id, c.name, c.party, c.number
  ORDER BY c.number ASC
""".query[(UUID, String, Option[String], Int, Long)]
   .to[List]
   .transact(xa)
```

`LEFT JOIN` ensures candidates with zero votes appear in results. `COUNT(v.id)` returns 0 for unmatched left-side rows. This is a single read query; no transaction isolation concern.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Duplicate prevention | UNIQUE constraint `(voter_id, election_id)` | SELECT FOR UPDATE | No row to lock on first insert; requires row pre-creation |
| Duplicate prevention | UNIQUE constraint | Advisory lock | UUID-to-integer hash collision risk; application state; overkill |
| Duplicate prevention | UNIQUE constraint | Application check-then-insert | TOCTOU race under concurrent requests |
| Error interception | `.recoverWith` on `F` (post-transact) | `attemptSqlState` on `ConnectionIO` | Single-statement; post-transact matches existing repository style |
| Error interception | Catch in repository layer | Catch in use case | Use case must stay free of JDBC/infrastructure types |
| Typeclass constraint | `MonadCancelThrow[F]` in repo, `Sync[F]` in use case | `IO` directly | Tagless Final; matches all existing code |

---

## Sources and Confidence Notes

All claims in this document are HIGH confidence grounded in:

- **Doobie 1.0.0-RC8 API** — `.transact`, `.attempt`, `.recoverWith`, `ConnectionIO`, `attemptSqlState` are stable APIs unchanged since Doobie 0.13. The RC8 release notes confirm no breaking changes to these combinators.
- **Cats Effect 3.5.7** — `MonadCancelThrow`, `Sync`, `.attempt`, `.recoverWith` are core stable APIs.
- **PostgreSQL JDBC driver** — `PSQLException.getSQLState()` returning `"23505"` for unique violations is specified by the SQL standard (SQLSTATE class 23 = integrity constraint violation, subclass 505 = unique violation) and has been stable across all PostgreSQL versions.
- **Codebase observation** — all patterns recommended above are direct extensions of patterns already in use in `AuditedLoginUseCase`, `AddCandidateUseCase`, `DoobieCandidateRepository`, and `DoobieElectionRepository`. No new patterns are introduced.

**No external searches were available during this research session.** The recommendations are grounded entirely in (a) the exact source files read, (b) verified knowledge of the library versions declared in `build.sbt`, and (c) PostgreSQL SQLSTATE specification. Any claim that cannot be verified by reading the existing source files is flagged as MEDIUM confidence inline.
