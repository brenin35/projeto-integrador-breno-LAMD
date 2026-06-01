# Caronascar — LAMD

**Aluno:** Breno de Oliveira Brandão
**Disciplina:** Engenharia de Software — Lab. de Desenvolvimento de Aplicações Móveis e Distribuídas
**Sprint:** 2 — 1º Semestre 2026

Marketplace de caronas intermunicipais (modelo BlaBlaCar). API REST em Node.js + Express + PostgreSQL,
com **mensageria assíncrona via RabbitMQ (MOM)** e **autenticação JWT**.

> 📄 Proposta completa do projeto: [Sprint_01-Proposta-LAMD.pdf](Sprint_01-Proposta-LAMD.pdf)

### Sprint 2 — MOM e autenticação

- Arquitetura orientada a eventos com **RabbitMQ** (Topic Exchange `caronascar.events`).
- O backend (**produtor**) publica eventos; um **worker** independente (consumidor) os processa.
- 📘 Eventos documentados: [docs/sprint2-eventos.md](docs/sprint2-eventos.md)
- 📝 Relatório de integração: [docs/sprint2-relatorio.md](docs/sprint2-relatorio.md)
- 🔐 Autenticação JWT (`/auth/register`, `/auth/login`); um mesmo usuário pode ser motorista
  (na viagem que publica) e passageiro (na solicitação que faz).
---

A API é documentada com **Swagger UI**. Após subir o backend, abra no navegador:

👉 **http://localhost:3000/docs**

Lá é possível ver todos os endpoints, schemas, exemplos de payload e testar cada rota direto pela interface (botão **"Try it out"**).

### Como rodar

Pré-requisitos: Node.js 20+, PostgreSQL 14+, Docker (para o RabbitMQ).

**1. Suba o RabbitMQ (MOM)** — na raiz do projeto:

```bash
docker compose up -d
```

Painel de gerenciamento: http://localhost:15672 (usuário `guest`, senha `guest`).

**2. Configure o backend:**

```bash
cd backend
npm install
```

Crie um arquivo `backend/.env` (veja `backend/.env.example`):

```
DATABASE_URL=postgresql://USUARIO:SENHA@127.0.0.1/labd
RABBITMQ_URL=amqp://guest:guest@localhost:5672
JWT_SECRET=troque-este-segredo
JWT_EXPIRES_IN=7d
```

Crie o banco e rode as migrações:

```bash
npm run db:migrate
```

**3. Suba a API e o worker** (em dois terminais):

```bash
npm run dev      # terminal 1 — API REST (produtor)
npm run worker   # terminal 2 — consumidor de eventos do RabbitMQ
```

Acesse:

- **http://localhost:3000/docs** — documentação Swagger UI (interativa)

### Fluxo de teste sugerido

Agora as rotas de escrita exigem **autenticação**, e o papel é **contextual**: o motorista de
uma viagem é quem a publica (vem do token, não do corpo); o passageiro de uma solicitação é
quem a cria. Faça tudo pelo Swagger UI em http://localhost:3000/docs — em cada rota clique em
**"Try it out"**, edite o corpo e **"Execute"**. Deixe o `npm run worker` rodando para ver as
notificações chegarem de forma assíncrona.

#### 1. Registrar o **motorista** — `POST /auth/register`

```json
{
  "name": "João Motorista",
  "email": "joao.motorista@example.com",
  "password": "senha123",
  "phone": "31999990001",
  "vehicle": "Toyota Corolla 2020 — placa ABC1D23"
}
```

A resposta (**201**) traz `{ "token": "...", "user": {...} }`. Copie o **token do motorista**.

#### 2. Registrar o **passageiro** — `POST /auth/register`

```json
{
  "name": "Ana Passageira",
  "email": "ana.passageira@example.com",
  "password": "senha123",
  "phone": "31999990002"
}
```

Copie o **token do passageiro**. (Para reentrar depois, use `POST /auth/login` com e-mail e senha.)

> ⚠️ O `email` é único: repetir o cadastro retorna **409 Conflict**.

#### 3. Autenticar no Swagger

Clique no botão **"Authorize"** (cadeado, topo da página), cole o **token do motorista** e
confirme. Todas as próximas requisições irão com `Authorization: Bearer <token>`.

#### 4. Publicar uma **viagem** — `POST /trips` (autenticado como motorista)

O `driverId` **não** vai no corpo — é o usuário do token:

```json
{
  "origin": "Belo Horizonte, MG",
  "destination": "Ouro Preto, MG",
  "departureAt": "2026-06-01T08:00:00.000Z",
  "totalSeats": 4,
  "pricePerSeat": "25.00",
  "notes": "Saída do bairro Funcionários, sem fumantes"
}
```

Copie o `id` da viagem — esse é o **`tripId`**. ➡️ O worker loga nada ainda; aguarde o passo 5.

#### 5. Solicitar uma **vaga** — `POST /seat-requests` (autenticado como passageiro)

Volte em **"Authorize"** e troque para o **token do passageiro**. O `passengerId` também vem
do token:

```json
{
  "tripId": "COLE_AQUI_O_ID_DA_VIAGEM",
  "seats": 1,
  "message": "Posso embarcar no centro?"
}
```

➡️ Observe no terminal do **worker**: `🔔 [notificação → motorista] Nova solicitação ...`
(evento `seat_request.created` consumido de forma assíncrona).

#### 6. Aceitar a solicitação — `PUT /seat-requests/{id}` (autenticado como motorista)

Troque de volta para o **token do motorista** e envie `{"status": "accepted"}`. ➡️ O worker
loga `🔔 [notificação → passageiro] ...` (evento `seat_request.status_changed`). Iniciar a
viagem com `PUT /trips/{id}` `{"status": "started"}` dispara `trip.status_changed`.

---

## Estrutura

```
docker-compose.yml              # RabbitMQ (MOM) para desenvolvimento
docs/                           # documentação dos eventos + relatório (Sprint 2)
backend/
├── index.ts                    # entrypoint (Express + Swagger UI)
├── src/
│   ├── openapi.ts              # spec OpenAPI 3.0 (fonte da verdade da doc)
│   ├── config/                 # conexão com o Postgres (Drizzle)
│   ├── controllers/            # rotas HTTP + validação Zod (inclui auth)
│   ├── services/               # acesso a dados + publicação de eventos
│   ├── models/                 # schema Drizzle (users, trips, seat_requests)
│   ├── auth/                   # JWT, hash de senha, middleware de autenticação
│   └── messaging/              # RabbitMQ: connection, publisher, events, consumer (worker)
└── drizzle/                    # migrações SQL geradas
```
