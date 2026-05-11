# Caronascar — LAMD

**Aluno:** Breno de Oliveira Brandão
**Disciplina:** Engenharia de Software — Lab. de Desenvolvimento de Aplicações Móveis e Distribuídas
**Sprint:** 1 — 1º Semestre 2026

Marketplace de caronas intermunicipais (modelo BlaBlaCar). API REST em Node.js + Express + PostgreSQL.

> 📄 Proposta completa do projeto: [Sprint_01-Proposta-LAMD.pdf](Sprint_01-Proposta-LAMD.pdf)
---

A API é documentada com **Swagger UI**. Após subir o backend, abra no navegador:

👉 **http://localhost:3000/docs**

Lá é possível ver todos os endpoints, schemas, exemplos de payload e testar cada rota direto pela interface (botão **"Try it out"**).

### Como rodar

Pré-requisitos: Node.js 20+, PostgreSQL 14+.

```bash
cd backend
npm install
```

Crie um arquivo `backend/.env` com a URL do seu banco PostgreSQL:

```
DATABASE_URL=postgresql://USUARIO:SENHA@127.0.0.1/labd
```

Crie o banco e rode as migrações:

```bash
npm run db:migrate
```

Suba o servidor:

```bash
npm run dev
```

Acesse:

- **http://localhost:3000/docs** — documentação Swagger UI (interativa)
- **http://localhost:3000/openapi.json** — spec OpenAPI 3.0 em JSON

### Fluxo de teste sugerido

A ordem importa por causa das chaves estrangeiras (uma viagem precisa de um motorista; uma solicitação precisa de uma viagem e de um passageiro). Faça tudo pela interface do Swagger UI em http://localhost:3000/docs — para cada rota, clique em **"Try it out"**, edite o corpo da requisição e clique em **"Execute"**.

#### 1. Criar o **motorista** — `POST /users`

Cole no corpo da requisição:

```json
{
  "name": "João Motorista",
  "email": "joao.motorista@example.com",
  "phone": "31999990001",
  "role": "driver",
  "vehicle": "Toyota Corolla 2020 — placa ABC1D23"
}
```

Na resposta (status **201**), copie o valor do campo `id`. Esse é o **`driverId`**.

#### 2. Criar o **passageiro** — `POST /users`

Cole no corpo da requisição:

```json
{
  "name": "Ana Passageira",
  "email": "ana.passageira@example.com",
  "phone": "31999990002",
  "role": "passenger"
}
```

Na resposta (status **201**), copie o valor do campo `id`. Esse é o **`passengerId`**.

> ⚠️ O campo `email` é único. Se você rodar esta mesma requisição duas vezes, a API retorna **409 Conflict**. Basta trocar o e-mail (ex.: `ana2@example.com`) ou apagar o usuário anterior via `DELETE /users/{id}`.

#### 3. Publicar uma **viagem** — `POST /trips`

Cole `driverId` (do passo 1) no JSON abaixo:

```json
{
  "driverId": "COLE_AQUI_O_ID_DO_MOTORISTA",
  "origin": "Belo Horizonte, MG",
  "destination": "Ouro Preto, MG",
  "departureAt": "2026-06-01T08:00:00.000Z",
  "totalSeats": 4,
  "pricePerSeat": "25.00",
  "notes": "Saída do bairro Funcionários, sem fumantes"
}
```

Copie o `id` da viagem retornada — esse é o **`tripId`**.

#### 4. Solicitar uma **vaga** — `POST /seat-requests`

Cole `tripId` (passo 3) e `passengerId` (passo 2):

```json
{
  "tripId": "COLE_AQUI_O_ID_DA_VIAGEM",
  "passengerId": "COLE_AQUI_O_ID_DO_PASSAGEIRO",
  "seats": 1,
  "message": "Posso embarcar no centro?"
}
```

#### 5. Explorar o resto

Use os endpoints **GET / PUT / DELETE** de cada recurso para listar, atualizar status (ex.: `PUT /seat-requests/{id}` com `{"status": "accepted"}`) ou remover.

---

## Estrutura

```
backend/
├── index.ts                    # entrypoint (Express + Swagger UI)
├── src/
│   ├── openapi.ts              # spec OpenAPI 3.0 (fonte da verdade da doc)
│   ├── config/                 # conexão com o Postgres (Drizzle)
│   ├── controllers/            # rotas HTTP + validação Zod
│   ├── services/               # acesso a dados
│   └── models/                 # schema Drizzle (users, trips, seat_requests)
└── drizzle/                    # migrações SQL geradas
```
