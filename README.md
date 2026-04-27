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
