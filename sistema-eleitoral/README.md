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
GET  /health
GET  /elections/11111111-1111-1111-1111-111111111111
POST /voters
POST /votes
GET  /results/11111111-1111-1111-1111-111111111111
WS   /audit/stream
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

- Trocar o repositório em memória por Doobie/PostgreSQL.
- Adicionar autenticação JWT/OAuth.
- Adicionar GraphQL se o docente exigir a recomendação do enunciado.
- Guardar `audit_log` de forma append-only.
- Criar relatório com diagrama de arquitetura, UML e gráfico de story points.
