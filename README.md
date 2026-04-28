# Sistema Eleitoral — Scala + Programação Funcional + Flutter

Projeto base para o TP2 de PEDWM: backend em Scala 3 com Cats Effect/http4s e frontend Flutter para web/mobile.

## Abrir no IntelliJ IDEA

1. Instalar plugins: **Scala**, **sbt**, **Flutter** e **Dart**.
2. `File > Open...` e escolher a pasta `sistema-eleitoral`.
3. Para o backend, importar como projeto sbt quando o IntelliJ pedir.
4. Para Flutter, abrir a pasta `frontend` como módulo/projeto Flutter. A documentação oficial da Flutter recomenda abrir o projeto existente com `Open`, não com “Project from existing sources”.

## Executar backend

```bash
cd backend
sbt run
```

API: `http://localhost:8080`

### Configuração por propriedades

O backend lê `backend/src/main/resources/application.properties` para:

- HTTP (`app.http.host`, `app.http.port`)
- GraphQL (`app.graphql.path`)
- WebSocket de auditoria (`app.websocket.audit.path`)
- Base de dados (`db.url`, `db.user`, `db.password`)

As variáveis de ambiente com os mesmos propósitos (`APP_HOST`, `APP_PORT`, `GRAPHQL_PATH`, `AUDIT_WS_PATH`, `DB_URL`, `DB_USER`, `DB_PASSWORD`) têm prioridade sobre o ficheiro.

> O backend precisa de PostgreSQL ativo em `localhost:5432`. Se receber
> `Connection to localhost:5432 refused`, inicie apenas a base de dados:

```bash
docker compose up -d postgres
```

> Se o porto `8080` já estiver ocupado (por exemplo, com `sbt run` local), ao
> subir Docker use outro porto para o backend:

```bash
BACKEND_HOST_PORT=8081 docker compose up -d
```

Endpoints principais:

```bash
POST /graphql
WS   /audit/stream
```

Exemplo GraphQL:

```json
{
  "query": "query Election($id: String!) { election(id: $id) { id title } }",
  "variables": { "id": "11111111-1111-1111-1111-111111111111" }
}
```

## Executar frontend Flutter

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

## Demonstração rápida

1. Arrancar backend.
2. Arrancar Flutter no Chrome.
3. Clicar em “Registar eleitor demo”.
4. Votar numa lista.
5. Ver resultados e evento WebSocket de auditoria.

## Próximos passos recomendados

- Adicionar autenticação JWT/OAuth.
- Implementar parser/engine GraphQL completo (schema/validation), em vez de roteamento por operação textual.
- Guardar `audit_log` de forma append-only no fluxo transacional.
- Criar relatório com diagrama de arquitetura, UML e gráfico de story points.

## SOLID aplicado no projeto

- **S (Single Responsibility):**
  - `AppConfig`/`ConfigProvider` tratam configuração.
  - `ElectionController` delega formatação de eventos WS para `AuditEventFrameEncoder`.
- **O (Open/Closed):**
  - Operações GraphQL usam tabela de handlers, facilitando extensão sem alterar o fluxo principal.
- **L (Liskov Substitution):**
  - Implementações de `ElectionRepository` (`InMemoryRepository`, `PostgresRepository`) permanecem substituíveis.
- **I (Interface Segregation):**
  - Contratos pequenos e específicos (`ElectionRepository`, `EventPublisher`, `AuditEventFrameEncoder`, `ConfigProvider`).
- **D (Dependency Inversion):**
  - `Main` depende de `ConfigProvider` (abstração), não do carregamento concreto.
  - `ElectionController` depende de `AuditEventFrameEncoder` (abstração), não da estratégia concreta.

## Design Patterns aplicados

- **Facade:** `ElectionApplicationFacade` centraliza a montagem de controller + service + repository e simplifica o `Main`.
- **Factory Method:** `RepositoryFactory` + `PostgresRepositoryFactory` encapsulam a criação de repositórios a partir do `Transactor`.

## Clean Architecture (resumo)

- **Interface Adapters (entrada):** `ElectionController` (HTTP/WS) traduz requests para casos de uso.
- **Application Layer:** `ElectionUseCases` (input port) e `ElectionUseCasesLive` (implementação).
- **Domain + Use Cases:** regras de negócio em `ElectionService` e modelo em `domain/*`.
- **Infrastructure (saída):** `PostgresRepository`/`InMemoryRepository`, `EventBus`, config/providers.
- **Composition Root:** `Main` + `ElectionApplicationFacade` fazem wiring das dependências.
