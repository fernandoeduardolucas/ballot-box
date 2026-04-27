# Arquitetura — Sistema Eleitoral

```mermaid
flowchart LR
  Flutter[Flutter Web/Mobile] -->|HTTP JSON| API[Scala http4s API]
  Flutter <-->|WebSocket auditoria| API
  API --> Service[Camada funcional: ElectionService]
  Service --> Repo[Repository]
  Service --> Bus[Event Bus]
  Repo --> Postgres[(PostgreSQL)]
  Bus --> Audit[(Audit Log)]
```

## Paradigmas usados
- Programação funcional: Cats Effect IO, EitherT, modelos imutáveis e serviços puros.
- Event-driven: EventBus com eventos de auditoria como VoteCast e UserRegistered.
- Orientação a aspetos: middleware de logging/CORS e ponto preparado para auditoria transversal.
- Frontend web/mobile: Flutter corre em Android/iOS/Web/Desktop com a mesma base de código.
