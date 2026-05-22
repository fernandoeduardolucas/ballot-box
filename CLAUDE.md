# VotoSeguro — ballot-box

Sistema eleitoral web/mobile (TP2 PEDWM). Backend Scala 3 + Cats Effect + http4s + Sangria + Doobie + PostgreSQL. Frontend Flutter.

## Project State

Active milestone: **Vote-Casting Feature** (Phase 1 of 3)

Planning docs: `.planning/` (local-only, not committed)

## Architecture

Clean Architecture + Tagless Final. Dependency direction: Infrastructure → Application ← Domain. API → Application.

- Domain: pure functions, no F[_] effects, no infra deps (`backend/.../identity/domain/`, `backend/.../election/domain/`)
- Application: `*Alg[F]` traits + `*UseCase` impls; all effects `F[_]`-polymorphic
- Infrastructure: Doobie repositories, BCrypt, JWT (`*infrastructure/`)
- AOP: decorator pattern (`aop/`) — wraps use cases for audit/logging
- API: Sangria GraphQL (`api/graphql/`) — all `IO` bridged via `Dispatcher.unsafeToFuture`
- Frontend: Flutter feature modules (`features/{election,identity}/`)

**New module pattern** (vote): add `vote/domain/`, `vote/application/`, `vote/infrastructure/` following exact same structure as `election/` bounded context.

## GSD Workflow

This project uses GSD for planning and execution.

- **Plan a phase:** `/gsd:plan-phase <N>`
- **Execute a phase:** `/gsd:execute-phase <N>`
- **Check progress:** `/gsd:progress`
- **Current phase:** Phase 1 — Schema & Domain Core

## Critical Constraints

1. **Ballot secrecy**: `AuditedCastVoteUseCase` must NOT log `candidateId` — only `voterId` + `electionId`
2. **Concurrency**: Primary guarantee is `UNIQUE (voter_id, election_id)` DB constraint; catch `PSQLException` SQLState 23505 in `DoobieVoteRepository` → `Left(AlreadyVoted)`
3. **Admin guard on queries**: `electionResults` in `QueryType` needs explicit admin check — no existing queries have guards
4. **candidateId validation**: must be validated against the specific election (not just existence)
5. **Flyway**: V7 migration is append-only; never edit after first apply
6. **Flutter route args**: VoteScreen must receive `VoteScreenArgs(election, candidates)` — never hardcode candidates

## Key Files

| File | Purpose |
|------|---------|
| `backend/.../Main.scala` | Wiring root — add new use cases here |
| `backend/.../api/graphql/ElectionContext.scala` | Request context — add `castVoteUseCase`, `getVoteResultsUseCase` |
| `backend/.../api/graphql/MutationType.scala` | Add `castVote` mutation here |
| `backend/.../api/graphql/QueryType.scala` | Add `electionResults` query here (with admin guard) |
| `backend/.../aop/AuditedLoginUseCase.scala` | Template for `AuditedCastVoteUseCase` |
| `backend/.../identity/domain/VoterRegistrationLogic.scala` | Template for `CastVoteLogic` (callback pattern) |
| `frontend/lib/features/election/data/election_service.dart` | Template for `VoteService` |
| `frontend/lib/main.dart` | Route definitions — update `/elections/vote` route |
| `frontend/lib/features/election/presentation/screens/vote_screen.dart` | Rewrite to use real data |

## Running Locally

```bash
# Start database
docker compose up -d postgres

# Backend (port 8080)
cd backend && sbt run

# Frontend (Chrome)
cd frontend && flutter run -d chrome
```

## Commit Convention

Follow existing commit messages: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
