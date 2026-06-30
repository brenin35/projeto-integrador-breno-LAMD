# Relatório Técnico Final — Caronascar

**Disciplina:** Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas (LAMD)
**Aluno:** Breno de Oliveira Brandão
**Instituição:** PUC Minas
**Semestre:** 1º Semestre de 2026

---

## 1. Introdução

O Caronascar é um marketplace de caronas intermunicipais desenvolvido ao longo de três sprints como projeto integrador da disciplina LAMD. O produto final cobre o fluxo completo de uma plataforma de carpooling: um motorista publica uma viagem; passageiros solicitam vagas; o motorista aceita ou recusa; todos os envolvidos recebem atualizações em tempo real, sem necessidade de recarregar a tela.

Este relatório descreve as decisões de arquitetura tomadas ao longo das sprints, com ênfase nos padrões estudados na disciplina (EDA, MOM, Clean Architecture e REST), nos desafios encontrados e nas soluções adotadas.

---

## 2. Visão Geral da Arquitetura

O sistema é composto por três processos principais e um broker de mensagens:

```
┌──────────────────────────────────────────────────────────────┐
│                        Cliente (Flutter)                     │
│  ┌────────────┐  HTTP/REST   ┌──────────────────────────┐   │
│  │  Screens   │◄────────────►│      Backend (Express)   │   │
│  │  Providers │  WebSocket   │  Controllers / Services  │   │
│  │  Services  │◄────────────►│  WS Gateway              │   │
│  └────────────┘              └──────────┬───────────────┘   │
└─────────────────────────────────────────│────────────────────┘
                                          │ AMQP
                              ┌───────────▼──────────────┐
                              │   RabbitMQ (MOM)         │
                              │  Topic Exchange           │
                              │  caronascar.events       │
                              └───────────┬──────────────┘
                                          │
                              ┌───────────▼──────────────┐
                              │  Worker (consumer.ts)    │
                              │  Notificações / Logs     │
                              └──────────────────────────┘
```

| Componente          | Tecnologia                          | Função                                                  |
| ------------------- | ----------------------------------- | ------------------------------------------------------- |
| Backend REST        | Node.js 20 + Express 5 + TypeScript | API, regras de negócio, persistência                    |
| Banco de dados      | PostgreSQL + Drizzle ORM            | Dados relacionais com migrações versionadas             |
| Broker de mensagens | RabbitMQ 3 (Docker)                 | Desacoplamento assíncrono entre produtor e consumidores |
| Worker              | Node.js (processo separado)         | Consumidor AMQP; simula notificações push/e-mail        |
| WS Gateway          | ws (WebSocket nativo Node.js)       | Empurra eventos do RabbitMQ para o app em tempo real    |
| App cliente         | Flutter 3 + Dart 3 + Provider       | Interface móvel do motorista e do passageiro            |

---

## 3. Padrões Estudados e Sua Aplicação

### 3.1 REST (Representational State Transfer)

A API segue as restrições REST definidas por Fielding (2000): interface uniforme, statelessness, e comunicação via representações de recursos. Os recursos principais são `/trips`, `/seat-requests` e `/auth`. Cada rota segue a semântica dos verbos HTTP:

- `GET /trips` — lista viagens (sem efeitos colaterais, cacheável)
- `POST /seat-requests` — cria uma solicitação (mudança de estado persistida)
- `PUT /seat-requests/:id` — altera status da solicitação (aceitar/recusar)
- `DELETE /trips/:id` — remove uma viagem

A documentação é gerada em **OpenAPI 3.0** e servida pelo Swagger UI em `/docs`, cumprindo o princípio de descoberta de recursos (HATEOAS parcial via links documentados).

Uma decisão relevante foi manter os GETs públicos e proteger apenas as escritas com JWT. Isso reflete a natureza de um marketplace: qualquer pessoa pode ver as viagens disponíveis, mas só usuários autenticados podem criar ou modificar recursos.

### 3.2 Arquitetura Orientada a Eventos (EDA)

Segundo Richards & Ford (2020), a EDA define sistemas em que os componentes se comunicam através da produção, detecção e consumo de eventos, sem acoplamento direto entre produtor e consumidor. No Caronascar, eventos de domínio são emitidos sempre que uma entidade muda de estado:

| Evento                        | Gatilho                                                       |
| ----------------------------- | ------------------------------------------------------------- |
| `seat_request.created`        | Passageiro solicita uma vaga                                  |
| `seat_request.status_changed` | Motorista aceita ou recusa                                    |
| `trip.created`                | Motorista publica uma nova viagem                             |
| `trip.status_changed`         | Viagem muda de `open` → `started` → `completed` / `cancelled` |

O backend (produtor) não conhece os consumidores. Ele publica no exchange e encerra sua responsabilidade. Quem processa — seja o worker de notificações, seja o gateway WebSocket — está desacoplado por contrato (routing key + payload). Isso torna o sistema extensível: adicionar um novo consumidor (ex.: e-mail transacional) não exige nenhuma mudança na API.

### 3.3 MOM — Middleware Orientado a Mensagens

O RabbitMQ foi escolhido como MOM por implementar o protocolo AMQP, que oferece garantias de entrega (persistência, ACK manual) e um modelo de roteamento expressivo. A topologia adotada foi o **Topic Exchange** (`caronascar.events`), conforme o padrão _Publish-Subscribe Channel_ descrito por Hohpe & Woolf (2003).

A estrutura de filas:

```
Exchange: caronascar.events (topic, durable)
│
├── notifications (durable)
│     bindings: seat_request.*
│                trip.status_changed
│
└── ws-gateway (durable)
      bindings: trip.*
                seat_request.*
```

Duas filas distintas consomem o mesmo exchange: a fila `notifications` alimenta o worker de log/notificação; a fila `ws-gateway` alimenta o gateway WebSocket que empurra eventos para o app Flutter. Esse é um exemplo claro do padrão _Competing Consumers_ (múltiplos consumidores na mesma fila) e _Message Filter_ (routing por wildcard).

A publicação é **resiliente**: falhas no broker são capturadas em try/catch e apenas logadas, sem derrubar a requisição HTTP. O dado já está persistido no PostgreSQL; o evento é best-effort.

### 3.4 Clean Architecture

O app Flutter e o backend seguem a estratégia de **camadas com dependência unidirecional**, inspirada no princípio de Clean Architecture (Martin, 2017): camadas externas dependem de internas, nunca o contrário.

**Backend (camadas de fora para dentro):**

```
Controllers (HTTP) → Services (regras de negócio) → Models (Drizzle/SQL)
                          ↓
                    Messaging (RabbitMQ) — efeito colateral após persistência
```

Controllers validam entrada (Zod), chamam o serviço e retornam a resposta. Serviços orquestram acesso ao banco e publicação de eventos. Modelos são apenas schema SQL (sem lógica). A autenticação JWT foi isolada em `src/auth/` (password.ts, jwt.ts, middleware.ts), sem vazamento para outras camadas.

**App Flutter (camadas de fora para dentro):**

```
Screens/Widgets → Providers (ChangeNotifier) → Services → Models
                       ↑
                  RealtimeService (WebSocket)
```

Telas não fazem HTTP diretamente; apenas observam providers via `context.watch<T>()`. Providers orquestram serviços e expõem dados prontos. Serviços traduzem JSON ↔ modelo. Modelos são classes imutáveis com factory `fromJson`. Essa separação facilita testes unitários dos serviços sem dependência do framework de UI.

---

## 4. Decisões de Design

### 4.1 WebSocket como camada de entrega em tempo real

A Sprint 3 exigia atualização assíncrona de estado. A solução implementada cria uma ponte entre o RabbitMQ e o WebSocket:

```
Backend publica evento → RabbitMQ → fila ws-gateway → WS Gateway → app Flutter
```

O gateway mantém um mapa `userId → WebSocket`. Ao consumir um evento da fila, ele identifica os destinatários (motorista da viagem, passageiros com solicitação ativa) e empurra via `ws.send()`. O app recebe em um `broadcast stream` do Dart e o provider reativo atualiza a UI sem polling.

Essa arquitetura traz uma consequência importante: o **mesmo evento** (`seat_request.status_changed`, por exemplo) é consumido por dois workers distintos — o de notificação (log) e o gateway WS — de forma independente e simultânea, sem que o produtor saiba ou precise coordenar.

### 4.2 Atualização otimista no app

Quando um `trip.created` chega via WebSocket, o app insere a nova viagem diretamente na lista local antes de confirmar com o servidor:

```dart
final newTrip = Trip.fromJson(ev.data);
if (!trips.any((t) => t.id == newTrip.id)) {
  trips = [newTrip, ...trips]
    ..sort((a, b) => a.departureAt.compareTo(b.departureAt));
}
notifyListeners(); // UI atualiza imediatamente
load();            // sync em background para consistência
```

Isso elimina a latência percebida: a lista aparece atualizada assim que o evento chega, sem aguardar o round-trip HTTP. O `load()` subsequente garante consistência caso haja discrepância.

### 4.3 Papel contextual do usuário

Diferentemente de sistemas com tipos de conta separados (conta-motorista vs. conta-passageiro), o Caronascar adota **papel contextual**: o mesmo usuário pode publicar uma viagem (agindo como motorista) e solicitar vaga em outra (agindo como passageiro). O papel é determinado pelo recurso, não pela conta:

- `driverId` de uma viagem = `sub` do JWT de quem a publicou
- `passengerId` de uma solicitação = `sub` do JWT de quem a criou

No app, um switch na AppBar alterna entre os modos "Passageiro" e "Motorista" sem exigir logout/login. Isso simplifica o modelo de usuário e o esquema do banco (uma única tabela `users`, sem coluna de papel).

### 4.4 Modo de operação duplo no app

O app utiliza `IndexedStack` para preservar o estado das telas de passageiro ao alternar para o modo motorista. As notificações de eventos WebSocket são centralizadas no `HomeShell` (sempre montado), garantindo que banners cheguem ao usuário independentemente da tela ativa.

---

## 5. Dificuldades e Soluções

### 5.1 Lista de viagens não atualizava em tempo real

**Problema:** ao criar uma viagem em um dispositivo, a lista do outro dispositivo só atualizava após logout/login. O evento `trip.created` chegava via WebSocket, o provider chamava `load()` assincronamente, mas a UI não reagia imediatamente.

**Solução:** Enriquecer o payload do evento `trip.created` com todos os campos da entidade (origin, destination, departureAt, etc.) e inserir o objeto diretamente na lista local, chamando `notifyListeners()` antes mesmo do HTTP retornar. O `load()` continua rodando em background para sincronização.

### 5.2 Notificações não apareciam no modo motorista

**Problema:** o código de snackbar estava dentro de `TripsScreen`, que é desmontada quando o usuário muda para o modo motorista. Eventos chegando nesse estado eram silenciados.

**Solução:** mover toda a lógica de banner/snackbar para `HomeShell`, que permanece montado durante toda a sessão do usuário. `HomeShell` observa `lastEventMessage` de todos os providers e exibe o snackbar via `WidgetsBinding.addPostFrameCallback`, evitando chamadas de setState durante o build.

### 5.3 Compatibilidade de tipagem do amqplib

**Problema:** a versão instalada do `amqplib` inclui tipagem própria com `ChannelModel`, diferente de tutoriais baseados em `Connection` da API legada.

**Solução:** adaptar a camada de conexão para usar `connect()` retornando `ChannelModel` e criar canais com `createChannel()`, sem depender de tipos externos do `@types/amqplib`.

### 5.4 Estado de viagem não refletido nos cards de solicitação

**Problema:** o card de solicitação do passageiro mostrava apenas o status da solicitação ("Aceita"), sem indicar que a viagem havia sido concluída ou iniciada.

**Solução:** passar o objeto `Trip` para o `SeatRequestCard` via prop e exibir um banner colorido no topo do card quando o status da viagem for diferente de `open` ou `full`. O banner reage em tempo real porque o `TripsProvider` já escuta eventos de `trip.status_changed`.

---

## 6. Reflexão sobre os Padrões Estudados

A construção do Caronascar tornou concretas abstrações que, em teoria, poderiam parecer excessivas para um projeto de escala acadêmica.

**REST** mostrou sua força na uniformidade: ao seguir as convenções de verbos e recursos, o Swagger UI funcionou sem configuração adicional de navegação, e clientes novos (como o app Flutter) conseguem consumir a API com contratos previsíveis.

**EDA e MOM** trouxeram o benefício mais visível: o motorista aceita uma solicitação, e o passageiro vê o chip mudar de "Pendente" para "Aceita" sem tocar na tela. Esse comportamento seria impossível com REST puro sem polling agressivo. A separação produtor/consumidor também permitiu adicionar o gateway WebSocket (Sprint 3) sem modificar o código da API REST (Sprint 2) — extensibilidade em prática.

O padrão **Topic Exchange** se mostrou mais adequado do que filas diretas: ao usar wildcards (`seat_request.*`, `trip.*`), novos eventos de um domínio são automaticamente roteados para todos os consumidores interessados, sem alterar o binding.

**Clean Architecture** no Flutter se pagou especialmente quando foi necessário centralizar as notificações no `HomeShell`. Como providers não dependem de widgets, foi possível reestruturar onde os banners eram exibidos sem tocar nos serviços ou na lógica de negócio. A mesma separação tornaria simples substituir o `RealtimeService` por SSE ou long-polling sem alterar nenhum provider.

A principal tensão encontrada foi entre **consistência eventual e experiência do usuário**: a atualização otimista entrega responsividade imediata, mas exige que o desenvolvedor pense em idempotência (evitar duplicatas na lista) e na reconciliação com o estado do servidor. Para um sistema de produção, seria necessário mecanismo de rollback caso o servidor retornasse erro após o insert otimista.

---

## 7. Conclusão

O Caronascar entrega um sistema de caronas funcional e reativo, construído sobre pilares que a disciplina LAMD propõe estudar: REST para contrato de API, MOM para desacoplamento assíncrono, EDA para reatividade em tempo real e Clean Architecture para manutenibilidade. Cada sprint adicionou uma camada de complexidade (persistência → mensageria → app móvel) de forma incremental, reforçando que arquiteturas distribuídas são construídas por composição de padrões bem definidos, não por tecnologias isoladas.
