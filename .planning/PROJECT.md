# VotoSeguro — Sistema Eleitoral

## What This Is

Sistema eleitoral web/mobile construído como TP2 de PEDWM. Backend em Scala 3 com Cats Effect/http4s e GraphQL (Sangria); frontend Flutter. Permite criar eleições, inscrever candidatos, registar eleitores e (após esta iteração) submeter votos reais com garantias de unicidade e concorrência.

## Core Value

Um eleitor autenticado consegue votar exactamente uma vez numa eleição activa — sem duplicados, sem race conditions — e o voto é persistido na base de dados.

## Requirements

### Validated

<!-- Funcionalidades já implementadas e em produção. -->

- ✓ Eleitor pode registar-se com ID civil + password + região NUT3 — Phase 0 / código existente
- ✓ Eleitor pode fazer login e receber JWT com claims (civilId, nut3Region, isAdmin) — Phase 0
- ✓ Admin pode criar eleições com título e datas (start/end) — Phase 0
- ✓ Admin pode adicionar candidatos a eleições (nome, partido, foto, número) — Phase 0
- ✓ Utilizador pode listar eleições activas — Phase 0
- ✓ Utilizador pode ver candidatos de uma eleição — Phase 0
- ✓ Eventos de login e registo são auditados em `audit_log` — Phase 0
- ✓ JWT protege mutations de admin (createElection, addCandidate) — Phase 0

### Active

<!-- Âmbito desta iteração. Hipóteses até entrar em produção. -->

- [ ] Eleitor autenticado consegue submeter um voto para um candidato numa eleição activa
- [ ] Sistema rejeita duplicados: um eleitor só vota uma vez por eleição (constraint DB + validação de aplicação)
- [ ] Sistema é seguro em concorrência: votos simultâneos do mesmo eleitor não produzem duplicados (UNIQUE constraint `(voter_id, election_id)`)
- [ ] Apenas eleitores autenticados (token JWT válido) podem votar
- [ ] VoteScreen carrega candidatos reais passados via argumento de rota (sem mock hardcoded)
- [ ] VoteCast é registado no `audit_log` (padrão AOP consistente com AuditedLoginUseCase)
- [ ] Admin consegue consultar contagem de votos por candidato em tempo real (`electionResults` query, admin-only)
- [ ] Tab "Resultados" no painel de admin mostra dados reais em vez do placeholder

### Out of Scope

- Resultados visíveis a não-admins durante a eleição — decisão do produto; apenas admin vê em tempo real
- Boletim cifrado/anónimo criptograficamente — UI menciona "cifrado" mas não é requisito desta iteração
- Push WebSocket de resultados em tempo real — V2; actualmente o audit stream existe mas não para votos
- Remoção ou alteração de votos — voto é irreversível por design
- Ligação entre NUT3 region do eleitor e eleições regionais — fora do âmbito do TP2

## Context

Projeto universitário (TP2 de PEDWM) com arquitectura Clean Architecture + Tagless Final. A layer de use cases usa traits `Alg[F[_]]` com implementações ligadas a `IO` apenas em `Main.scala`. Cross-cutting concerns (audit, logging) são decorators AOP que envolvem os use cases.

A tabela `votes` não existe ainda — será criada via Flyway migration V7. O `VoteScreen` actual usa candidatos hardcoded (`_Candidate` com `id: Int`) sem qualquer ligação ao backend.

Migrations actuais: V1 (voters) · V2 (audit_log) · V3 (elections) · V4 (candidates) · V5 (nut3_region) · V6 (is_admin).

O `ElectionDetailScreen` já navega para `/elections/vote` passando `ElectionItem` como argumento, mas o `VoteScreen` ignora-o. A lista de candidatos é carregada no `ElectionDetailScreen` e deve ser passada junto com a eleição para evitar segunda chamada ao backend.

## Constraints

- **Tech stack**: Scala 3 + Cats Effect + http4s + Sangria + Doobie + Flutter — não introduzir novas dependências sem justificação
- **Arquitectura**: Clean Architecture com Tagless Final — novos módulos seguem o padrão `domain → application (Alg + UseCase) → infrastructure (Doobie) → api (GraphQL)`
- **Concorrência**: garantida por `UNIQUE (voter_id, election_id)` na BD, não por locks de aplicação
- **Auth**: apenas eleitores com JWT válido podem votar; admin-check para `electionResults`
- **Flyway**: nova migration deve ser V7, não pode alterar migrations existentes
- **Flutter routing**: VoteScreen recebe `VoteScreenArgs(election, candidates)` via `ModalRoute.settings.arguments`

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| UNIQUE constraint em vez de advisory lock | Mais simples, garantia ao nível da BD, sem estado partilhado na aplicação | — Pending |
| Admin-only para resultados em tempo real | Decisão de produto confirmada pelo utilizador | — Pending |
| Passar candidatos como argumento de rota | Candidatos já carregados no ElectionDetailScreen; evita segunda query | — Pending |
| AuditedCastVoteUseCase decorator | Consistência com AuditedLoginUseCase; auditoria de votos no audit_log | — Pending |

## Evolution

Este documento evolui em transições de fase e limites de milestone.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-21 after initialization*
