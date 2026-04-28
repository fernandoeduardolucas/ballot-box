# Relatório Técnico — Sistema Eleitoral

## 1. Visão Geral

O projeto implementa um sistema eleitoral com:

- **Backend** em Scala 3 com `cats-effect`, `http4s` e `doobie`;
- **Frontend** em Flutter (web/mobile);
- **Persistência** em PostgreSQL;
- **Comunicação** por HTTP (GraphQL-like) e WebSocket (auditoria em tempo real).

---

## 2. Stack e Componentes

### 2.1 Backend

- `Main.scala`: ponto de entrada e bootstrap da aplicação.
- `config/`: carregamento e abstração de configurações (`AppConfig`, `ConfigProvider`).
- `domain/`: modelo de domínio (IDs tipados, entidades, erros e eventos).
- `repository/`: contrato de persistência (`ElectionRepository`).
- `infra/`: implementações concretas:
  - `InMemoryRepository`;
  - `PostgresRepository`;
  - `EventBus`;
  - `RepositoryFactory`.
- `services/`: regra de negócio (`ElectionService` + interface `ElectionServiceAlg`).
- `api/`: codecs JSON, encoder de eventos para WebSocket e controller HTTP/WS.
- `aop/`: logging transversal com `LoggingAspect`.
- `app/`: `ElectionApplicationFacade` para composição da aplicação.

### 2.2 Frontend

- `frontend/lib/main.dart`: ecrã principal, chamadas GraphQL via HTTP e subscrição de auditoria via WebSocket.

### 2.3 Base de Dados

- `db/001_schema.sql`: criação de tabelas.
- `db/002_seed.sql`: dados iniciais para demonstração.

---

## 3. Arquitetura e Fluxo Técnico

### 3.1 Fluxo de Pedido (GraphQL-like)

1. Cliente envia `POST` para endpoint configurável GraphQL.
2. `ElectionController` identifica operação pela query (`health`, `election`, `registerVoter`, `vote`, `results`).
3. Controller valida variáveis e delega no serviço/repositório.
4. Serviço aplica regras de negócio e publica eventos de auditoria.
5. Resposta JSON é devolvida ao cliente.

### 3.2 Fluxo de Auditoria (WebSocket)

1. Cliente abre ligação para endpoint WS configurável.
2. `EventBus` fornece stream de eventos.
3. `AuditEventFrameEncoder` converte `AuditEvent` para `WebSocketFrame`.
4. Cliente recebe eventos em tempo real (registo, voto, etc.).

---

## 4. Configuração Runtime

Foi introduzida configuração central com:

- Ficheiro: `backend/src/main/resources/application.properties`;
- Overrides por variáveis de ambiente:
  - `APP_HOST`, `APP_PORT`;
  - `GRAPHQL_PATH`, `AUDIT_WS_PATH`;
  - `DB_URL`, `DB_USER`, `DB_PASSWORD`.

Com isto, host/porto HTTP, paths de GraphQL/WS e credenciais de BD podem ser alterados sem tocar no código.

---

## 5. Persistência e Modelo de Dados

### 5.1 Tabelas

- `elections`
- `candidates`
- `voters`
- `votes`
- `audit_log`

### 5.2 Repositórios

- `InMemoryRepository`: útil para testes e desenvolvimento rápido.
- `PostgresRepository`: implementação real com SQL via Doobie.

Ambos implementam `ElectionRepository`, garantindo substituição transparente.

---

## 6. Regras de Negócio Implementadas

No `ElectionService`:

- Registo de eleitor;
- Validação de voto:
  - eleição existente;
  - eleitor existente;
  - período de votação válido;
  - elegibilidade do eleitor;
  - prevenção de voto duplicado;
- Cálculo de resultados por candidato;
- Publicação de eventos de auditoria (`UserRegistered`, `VoteCast`).

---

## 7. Padrões e Princípios Aplicados

## 7.1 SOLID

- **SRP**: separação clara entre configuração, API, domínio, persistência e logging.
- **OCP**: resolução GraphQL por tabela de handlers extensível.
- **LSP**: `InMemoryRepository` e `PostgresRepository` substituem-se via `ElectionRepository`.
- **ISP**: interfaces pequenas e específicas (`EventPublisher`, `ConfigProvider`, `AuditEventFrameEncoder`).
- **DIP**: composição depende de abstrações em vez de implementações concretas.

## 7.2 Design Patterns

- **Facade**: `ElectionApplicationFacade` centraliza a montagem de componentes.
- **Factory Method**: `RepositoryFactory` e `PostgresRepositoryFactory` encapsulam criação de repositórios.
- **Decorator/AOP**: `LoggedElectionService` adiciona logging sem alterar a lógica core.

---

## 8. Observabilidade e Operação

- Logging transversal de operações no serviço (início/fim/erro e duração).
- Stream de auditoria por WebSocket para monitorização em tempo real.
- Configuração de endpoints e infraestrutura externalizada em propriedades/env.

---

## 9. Testes e Qualidade

- Existe teste unitário (`ElectionServiceSuite`) para cenário crítico:
  - eleitor elegível vota com sucesso;
  - tentativa de segundo voto falha.

> Nota operacional: no ambiente atual, a execução automática de `sbt test` depende da instalação de `sbt`.

---

## 10. Estado Atual e Próximos Passos Técnicos

### Estado atual

- Backend funcional com API GraphQL-like e WS de auditoria.
- Configuração externalizada.
- Persistência preparada com schema e seed.
- Estrutura modular com padrões arquiteturais aplicados.

### Próximos passos sugeridos

1. Substituir parser textual GraphQL por engine com schema/validação formal.
2. Persistir eventos de auditoria em `audit_log` de forma transacional.
3. Introduzir autenticação/autorização (JWT/OAuth2).
4. Aumentar cobertura de testes (integração API + repositório PostgreSQL).
5. Adicionar CI para lint, build e testes automáticos.
