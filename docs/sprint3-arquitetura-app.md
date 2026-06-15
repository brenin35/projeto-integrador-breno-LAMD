# Sprint 3 — Arquitetura do App Flutter (Cliente)

App do **passageiro** (`app_cliente/`), em Flutter + Provider, seguindo Clean Architecture:
camadas com dependência só "para baixo" (UI → estado → serviços → modelos).

## Camadas

```mermaid
flowchart TD
    subgraph UI["Apresentação — screens/ + widgets/"]
      LOGIN[LoginScreen]
      HOME[HomeShell]
      TRIPS[TripsScreen]
      DET[TripDetailsScreen]
      MINE[MyRequestsScreen]
      CARDS[TripCard / SeatRequestCard / StatusChip]
    end

    subgraph STATE["Estado — state/ (ChangeNotifier + Provider)"]
      AP[AuthProvider]
      TP[TripsProvider]
      MP[MyRequestsProvider]
    end

    subgraph SVC["Serviços — services/"]
      API[ApiClient REST]
      AUTH[AuthService]
      TRIP[TripService]
      SR[SeatRequestService]
      RT[RealtimeService - WebSocket]
    end

    subgraph MODEL["Modelos — models/"]
      U[User]
      T[Trip]
      S[SeatRequest]
    end

    UI --> STATE
    STATE --> SVC
    SVC --> MODEL
    AUTH --> API
    TRIP --> API
    SR --> API
    RT -. stream de eventos .-> MP
    AP -. injeta token / conecta WS .-> API
    AP -. conecta .-> RT
```

| Camada | Pasta | Responsabilidade |
|---|---|---|
| Apresentação | `screens/`, `widgets/` | Telas e componentes visuais. Sem regra de negócio nem HTTP. |
| Estado | `state/` | `ChangeNotifier` por feature; orquestra serviços e expõe dados à UI. |
| Serviços | `services/` | Acesso a dados: REST (`ApiClient` + `*Service`) e tempo real (`RealtimeService`). |
| Modelos | `models/` | Entidades imutáveis com `fromJson` (`User`, `Trip`, `SeatRequest`). |
| Suporte | `config.dart`, `utils/` | Endereços do backend e helpers (ex.: formatação de data). |

## Telas (mínimo de 3 — entregamos 4 + login)

1. **TripsScreen** — listagem de viagens disponíveis (`GET /trips`, filtradas: abertas e com vaga).
2. **TripDetailsScreen** — detalhes + **ação principal**: solicitar vaga (`POST /seat-requests`).
3. **MyRequestsScreen** — minhas solicitações, com **atualização em tempo real**.
4. **LoginScreen** — login/cadastro (`POST /auth/login` e `/auth/register`).

## Integração com o backend REST

`ApiClient` centraliza base URL, cabeçalhos e o token JWT (injeta `Authorization: Bearer`).
Cada `*Service` traduz JSON ↔ modelos. Ex. de fluxo:

`TripsScreen` → `TripsProvider.load()` → `TripService.listAvailable()` → `ApiClient.get('/trips')` → backend.

## Atualização assíncrona de estado (WebSocket / MOM)

Quando o motorista aceita uma solicitação, o backend publica `seat_request.status_changed`
no RabbitMQ; o **gateway WebSocket** (no backend) consome esse evento e empurra para o
passageiro conectado. No app:

```mermaid
sequenceDiagram
    participant API as Backend + WS Gateway
    participant MOM as RabbitMQ
    participant RT as RealtimeService
    participant MP as MyRequestsProvider
    participant UI as MyRequestsScreen
    API->>MOM: publish seat_request.status_changed
    MOM-->>API: fila "ws-gateway" consome
    API-->>RT: WebSocket push {type, data}
    RT->>MP: evento no stream
    MP->>MP: atualiza o status da solicitação
    MP-->>UI: notifyListeners() → rebuild (chip vira "Aceita") + snackbar
```

Ou seja: **sem polling** e **sem o usuário mexer na tela** — exatamente o critério de
"atualização assíncrona de estado" da Sprint 3. A escolha por WebSocket reaproveita o MOM
da Sprint 2 (o mesmo evento ainda vai, em paralelo, para o worker `notifications`).
