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

A ordem importa por causa das chaves estrangeiras (uma viagem precisa de um motorista; uma solicitação precisa de uma viagem e de um passageiro):

1. **POST `/users`** — crie um motorista (`role: "driver"`). Copie o `id` retornado.
2. **POST `/users`** — crie um passageiro (`role: "passenger"`). Copie o `id` retornado.
3. **POST `/trips`** — publique uma viagem usando o `id` do motorista no campo `driverId`.
4. **POST `/seat-requests`** — solicite uma vaga usando `tripId` (da viagem) e `passengerId` (do passageiro).
5. Liste / atualize / remova os recursos via **GET / PUT / DELETE**.

> ⚠️ Os exemplos no Swagger usam `maria@example.com` etc. O e-mail é único — ao testar mais de uma vez, troque o e-mail ou apague o usuário anterior. A API retorna **409 Conflict** quando o e-mail já existe.

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
