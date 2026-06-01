export const openApiDoc = {
    openapi: '3.0.3',
    info: {
        title: 'Caronascar API',
        version: '1.0.0',
        description: [
            '# Caronascar',
            '',
            'API REST do **Caronascar**, um marketplace de caronas intermunicipais que conecta motoristas que planejam uma viagem a passageiros que precisam ir ao mesmo destino. Inspirado no modelo do BlaBlaCar.',
            '',
            '## Recursos',
            '',
            '- **Users** — motoristas (`driver`) e passageiros (`passenger`).',
            '- **Trips** — viagens publicadas pelos motoristas (origem, destino, partida, vagas, preço).',
            '- **Seat Requests** — solicitações de vaga feitas por passageiros, vinculadas a uma viagem.',
            '',
            '## Ciclo de vida',
            '',
            '- Trip: `open` → `full` → `started` → `completed` (ou `cancelled` em qualquer ponto).',
            '- Seat Request: `pending` → `accepted` / `rejected` / `cancelled`.',
        ].join('\n'),
    },
    servers: [
        { url: 'http://localhost:3000', description: 'Desenvolvimento local' },
    ],
    tags: [
        { name: 'Auth', description: 'Registro e login (JWT). Use o token no botão "Authorize".' },
        { name: 'Users', description: 'Cadastro de usuários' },
        { name: 'Trips', description: 'Viagens publicadas pelos motoristas' },
        { name: 'Seat Requests', description: 'Solicitações de vaga feitas pelos passageiros' },
    ],
    components: {
        securitySchemes: {
            bearerAuth: {
                type: 'http',
                scheme: 'bearer',
                bearerFormat: 'JWT',
                description: 'Token JWT retornado por POST /auth/login ou /auth/register.',
            },
        },
        schemas: {
            UUID: {
                type: 'string',
                format: 'uuid',
                example: '00000000-0000-0000-0000-000000000000',
            },
            ValidationError: {
                type: 'array',
                description: 'Lista de erros de validação retornada pelo Zod',
                items: {
                    type: 'object',
                    properties: {
                        path: { type: 'array', items: { type: 'string' } },
                        message: { type: 'string' },
                        code: { type: 'string' },
                    },
                },
            },
            NotFound: {
                type: 'object',
                properties: { error: { type: 'string', example: 'User not found' } },
            },
            ErrorMessage: {
                type: 'object',
                properties: { error: { type: 'string' } },
            },
            RegisterBody: {
                type: 'object',
                required: ['name', 'email', 'password'],
                properties: {
                    name: { type: 'string', maxLength: 120, example: 'Maria Silva' },
                    email: { type: 'string', format: 'email', maxLength: 200, example: 'maria@example.com' },
                    password: { type: 'string', minLength: 6, maxLength: 72, example: 'senha123' },
                    phone: { type: 'string', maxLength: 20, example: '11999999999' },
                    vehicle: { type: 'string', maxLength: 120, example: 'Toyota Corolla 2020 — placa ABC1D23' },
                },
            },
            LoginBody: {
                type: 'object',
                required: ['email', 'password'],
                properties: {
                    email: { type: 'string', format: 'email', example: 'maria@example.com' },
                    password: { type: 'string', example: 'senha123' },
                },
            },
            AuthResponse: {
                type: 'object',
                properties: {
                    token: { type: 'string', description: 'JWT — use em Authorization: Bearer <token>' },
                    user: { $ref: '#/components/schemas/User' },
                },
            },
            User: {
                type: 'object',
                properties: {
                    id: { $ref: '#/components/schemas/UUID' },
                    name: { type: 'string', maxLength: 120, example: 'Maria Silva' },
                    email: { type: 'string', format: 'email', example: 'maria@example.com' },
                    phone: { type: 'string', maxLength: 20, nullable: true, example: '11999999999' },
                    vehicle: { type: 'string', maxLength: 120, nullable: true, example: 'Toyota Corolla 2020 — placa ABC1D23' },
                    rating: { type: 'string', nullable: true, example: '5.00', description: 'Avaliação média (0.00–5.00). Definida pelo sistema.' },
                    createdAt: { type: 'string', format: 'date-time', nullable: true },
                    updatedAt: { type: 'string', format: 'date-time', nullable: true },
                },
            },
            CreateUserBody: {
                type: 'object',
                required: ['name', 'email'],
                properties: {
                    name: { type: 'string', maxLength: 120, example: 'Maria Silva' },
                    email: { type: 'string', format: 'email', maxLength: 200, example: 'maria@example.com' },
                    phone: { type: 'string', maxLength: 20, example: '11999999999' },
                    vehicle: { type: 'string', maxLength: 120, example: 'Toyota Corolla 2020 — placa ABC1D23' },
                },
            },
            UpdateUserBody: {
                type: 'object',
                properties: {
                    name: { type: 'string', maxLength: 120 },
                    email: { type: 'string', format: 'email', maxLength: 200 },
                    phone: { type: 'string', maxLength: 20 },
                    vehicle: { type: 'string', maxLength: 120 },
                },
            },
            Trip: {
                type: 'object',
                properties: {
                    id: { $ref: '#/components/schemas/UUID' },
                    driverId: { $ref: '#/components/schemas/UUID' },
                    origin: { type: 'string', maxLength: 300, example: 'Belo Horizonte, MG' },
                    destination: { type: 'string', maxLength: 300, example: 'Ouro Preto, MG' },
                    departureAt: { type: 'string', format: 'date-time', example: '2026-06-01T08:00:00.000Z' },
                    totalSeats: { type: 'integer', minimum: 1, maximum: 8, example: 4 },
                    availableSeats: { type: 'integer', minimum: 0, example: 4 },
                    pricePerSeat: { type: 'string', example: '25.00', description: 'Decimal armazenado como string (precisão monetária)' },
                    notes: { type: 'string', nullable: true, example: 'Saída do bairro Funcionários, sem fumantes' },
                    status: { type: 'string', enum: ['open', 'full', 'started', 'completed', 'cancelled'], example: 'open' },
                    startedAt: { type: 'string', format: 'date-time', nullable: true },
                    completedAt: { type: 'string', format: 'date-time', nullable: true },
                    createdAt: { type: 'string', format: 'date-time', nullable: true },
                    updatedAt: { type: 'string', format: 'date-time', nullable: true },
                },
            },
            CreateTripBody: {
                type: 'object',
                required: ['origin', 'destination', 'departureAt', 'totalSeats', 'pricePerSeat'],
                description: 'Requer autenticação. O `driverId` é o usuário do token (não vai no corpo). `availableSeats` recebe o valor de `totalSeats` e `status` inicial é `open`.',
                properties: {
                    origin: { type: 'string', maxLength: 300, example: 'Belo Horizonte, MG' },
                    destination: { type: 'string', maxLength: 300, example: 'Ouro Preto, MG' },
                    departureAt: { type: 'string', format: 'date-time', example: '2026-06-01T08:00:00.000Z' },
                    totalSeats: { type: 'integer', minimum: 1, maximum: 8, example: 4 },
                    pricePerSeat: { type: 'string', example: '25.00' },
                    notes: { type: 'string', example: 'Saída do bairro Funcionários, sem fumantes' },
                },
            },
            UpdateTripBody: {
                type: 'object',
                properties: {
                    availableSeats: { type: 'integer', minimum: 0 },
                    status: { type: 'string', enum: ['open', 'full', 'started', 'completed', 'cancelled'] },
                    notes: { type: 'string' },
                },
            },
            SeatRequest: {
                type: 'object',
                properties: {
                    id: { $ref: '#/components/schemas/UUID' },
                    tripId: { $ref: '#/components/schemas/UUID' },
                    passengerId: { $ref: '#/components/schemas/UUID' },
                    seats: { type: 'integer', minimum: 1, example: 1 },
                    message: { type: 'string', nullable: true, example: 'Posso embarcar no centro?' },
                    status: { type: 'string', enum: ['pending', 'accepted', 'rejected', 'cancelled'], example: 'pending' },
                    respondedAt: { type: 'string', format: 'date-time', nullable: true },
                    createdAt: { type: 'string', format: 'date-time', nullable: true },
                    updatedAt: { type: 'string', format: 'date-time', nullable: true },
                },
            },
            CreateSeatRequestBody: {
                type: 'object',
                required: ['tripId'],
                description: 'Requer autenticação. O `passengerId` é o usuário do token (não vai no corpo). `status` inicial é `pending`.',
                properties: {
                    tripId: { $ref: '#/components/schemas/UUID' },
                    seats: { type: 'integer', minimum: 1, default: 1, example: 1 },
                    message: { type: 'string', example: 'Posso embarcar no centro?' },
                },
            },
            UpdateSeatRequestBody: {
                type: 'object',
                properties: {
                    status: { type: 'string', enum: ['pending', 'accepted', 'rejected', 'cancelled'] },
                    seats: { type: 'integer', minimum: 1 },
                    message: { type: 'string' },
                },
            },
        },
        parameters: {
            IdPath: {
                name: 'id',
                in: 'path',
                required: true,
                schema: { $ref: '#/components/schemas/UUID' },
            },
        },
        responses: {
            ValidationError: {
                description: 'Corpo inválido',
                content: { 'application/json': { schema: { $ref: '#/components/schemas/ValidationError' } } },
            },
            NotFound: {
                description: 'Recurso não encontrado',
                content: { 'application/json': { schema: { $ref: '#/components/schemas/NotFound' } } },
            },
            NoContent: { description: 'Removido com sucesso' },
            Unauthorized: {
                description: 'Token ausente ou inválido',
                content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorMessage' } } },
            },
            Forbidden: {
                description: 'Sem permissão para esta ação (não é o dono do recurso)',
                content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorMessage' } } },
            },
        },
    },
    paths: {
        '/auth/register': {
            post: {
                tags: ['Auth'],
                summary: 'Registrar usuário e obter token JWT',
                requestBody: {
                    required: true,
                    content: { 'application/json': { schema: { $ref: '#/components/schemas/RegisterBody' } } },
                },
                responses: {
                    '201': {
                        description: 'Usuário registrado',
                        content: { 'application/json': { schema: { $ref: '#/components/schemas/AuthResponse' } } },
                    },
                    '400': { $ref: '#/components/responses/ValidationError' },
                    '409': {
                        description: 'E-mail já cadastrado',
                        content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorMessage' } } },
                    },
                },
            },
        },
        '/auth/login': {
            post: {
                tags: ['Auth'],
                summary: 'Login e obtenção do token JWT',
                requestBody: {
                    required: true,
                    content: { 'application/json': { schema: { $ref: '#/components/schemas/LoginBody' } } },
                },
                responses: {
                    '200': {
                        description: 'Autenticado',
                        content: { 'application/json': { schema: { $ref: '#/components/schemas/AuthResponse' } } },
                    },
                    '400': { $ref: '#/components/responses/ValidationError' },
                    '401': { $ref: '#/components/responses/Unauthorized' },
                },
            },
        },
        '/users': {
            post: {
                tags: ['Users'],
                summary: 'Criar usuário',
                requestBody: {
                    required: true,
                    content: { 'application/json': { schema: { $ref: '#/components/schemas/CreateUserBody' } } },
                },
                responses: {
                    '201': {
                        description: 'Usuário criado',
                        content: { 'application/json': { schema: { $ref: '#/components/schemas/User' } } },
                    },
                    '400': { $ref: '#/components/responses/ValidationError' },
                },
            },
            get: {
                tags: ['Users'],
                summary: 'Listar todos os usuários',
                responses: {
                    '200': {
                        description: 'Lista de usuários',
                        content: { 'application/json': { schema: { type: 'array', items: { $ref: '#/components/schemas/User' } } } },
                    },
                },
            },
        },
        '/users/{id}': {
            parameters: [{ $ref: '#/components/parameters/IdPath' }],
            get: {
                tags: ['Users'],
                summary: 'Buscar usuário por ID',
                responses: {
                    '200': {
                        description: 'Usuário encontrado',
                        content: { 'application/json': { schema: { $ref: '#/components/schemas/User' } } },
                    },
                    '404': { $ref: '#/components/responses/NotFound' },
                },
            },
            put: {
                tags: ['Users'],
                summary: 'Atualizar usuário',
                requestBody: {
                    required: true,
                    content: { 'application/json': { schema: { $ref: '#/components/schemas/UpdateUserBody' } } },
                },
                responses: {
                    '200': {
                        description: 'Usuário atualizado',
                        content: { 'application/json': { schema: { $ref: '#/components/schemas/User' } } },
                    },
                    '400': { $ref: '#/components/responses/ValidationError' },
                },
            },
            delete: {
                tags: ['Users'],
                summary: 'Remover usuário',
                responses: { '204': { $ref: '#/components/responses/NoContent' } },
            },
        },
        '/trips': {
            post: {
                tags: ['Trips'],
                summary: 'Publicar viagem',
                security: [{ bearerAuth: [] }],
                requestBody: {
                    required: true,
                    content: { 'application/json': { schema: { $ref: '#/components/schemas/CreateTripBody' } } },
                },
                responses: {
                    '201': {
                        description: 'Viagem publicada',
                        content: { 'application/json': { schema: { $ref: '#/components/schemas/Trip' } } },
                    },
                    '400': { $ref: '#/components/responses/ValidationError' },
                    '401': { $ref: '#/components/responses/Unauthorized' },
                },
            },
            get: {
                tags: ['Trips'],
                summary: 'Listar todas as viagens',
                responses: {
                    '200': {
                        description: 'Lista de viagens',
                        content: { 'application/json': { schema: { type: 'array', items: { $ref: '#/components/schemas/Trip' } } } },
                    },
                },
            },
        },
        '/trips/{id}': {
            parameters: [{ $ref: '#/components/parameters/IdPath' }],
            get: {
                tags: ['Trips'],
                summary: 'Buscar viagem por ID',
                responses: {
                    '200': {
                        description: 'Viagem encontrada',
                        content: { 'application/json': { schema: { $ref: '#/components/schemas/Trip' } } },
                    },
                    '404': { $ref: '#/components/responses/NotFound' },
                },
            },
            put: {
                tags: ['Trips'],
                summary: 'Atualizar viagem',
                description: 'Apenas o motorista dono da viagem.',
                security: [{ bearerAuth: [] }],
                requestBody: {
                    required: true,
                    content: { 'application/json': { schema: { $ref: '#/components/schemas/UpdateTripBody' } } },
                },
                responses: {
                    '200': {
                        description: 'Viagem atualizada',
                        content: { 'application/json': { schema: { $ref: '#/components/schemas/Trip' } } },
                    },
                    '400': { $ref: '#/components/responses/ValidationError' },
                    '401': { $ref: '#/components/responses/Unauthorized' },
                    '403': { $ref: '#/components/responses/Forbidden' },
                    '404': { $ref: '#/components/responses/NotFound' },
                },
            },
            delete: {
                tags: ['Trips'],
                summary: 'Remover viagem',
                description: 'Apenas o motorista dono da viagem.',
                security: [{ bearerAuth: [] }],
                responses: {
                    '204': { $ref: '#/components/responses/NoContent' },
                    '401': { $ref: '#/components/responses/Unauthorized' },
                    '403': { $ref: '#/components/responses/Forbidden' },
                    '404': { $ref: '#/components/responses/NotFound' },
                },
            },
        },
        '/seat-requests': {
            post: {
                tags: ['Seat Requests'],
                summary: 'Solicitar vaga em uma viagem',
                description: 'Requer autenticação. O passageiro é o usuário do token.',
                security: [{ bearerAuth: [] }],
                requestBody: {
                    required: true,
                    content: { 'application/json': { schema: { $ref: '#/components/schemas/CreateSeatRequestBody' } } },
                },
                responses: {
                    '201': {
                        description: 'Solicitação criada',
                        content: { 'application/json': { schema: { $ref: '#/components/schemas/SeatRequest' } } },
                    },
                    '400': { $ref: '#/components/responses/ValidationError' },
                    '401': { $ref: '#/components/responses/Unauthorized' },
                    '409': {
                        description: 'Já existe solicitação para essa viagem',
                        content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorMessage' } } },
                    },
                },
            },
            get: {
                tags: ['Seat Requests'],
                summary: 'Listar todas as solicitações de vaga',
                responses: {
                    '200': {
                        description: 'Lista de solicitações',
                        content: { 'application/json': { schema: { type: 'array', items: { $ref: '#/components/schemas/SeatRequest' } } } },
                    },
                },
            },
        },
        '/seat-requests/{id}': {
            parameters: [{ $ref: '#/components/parameters/IdPath' }],
            get: {
                tags: ['Seat Requests'],
                summary: 'Buscar solicitação por ID',
                responses: {
                    '200': {
                        description: 'Solicitação encontrada',
                        content: { 'application/json': { schema: { $ref: '#/components/schemas/SeatRequest' } } },
                    },
                    '404': { $ref: '#/components/responses/NotFound' },
                },
            },
            put: {
                tags: ['Seat Requests'],
                summary: 'Atualizar solicitação (aceitar/recusar)',
                description: 'Apenas o motorista da viagem associada pode responder.',
                security: [{ bearerAuth: [] }],
                requestBody: {
                    required: true,
                    content: { 'application/json': { schema: { $ref: '#/components/schemas/UpdateSeatRequestBody' } } },
                },
                responses: {
                    '200': {
                        description: 'Solicitação atualizada',
                        content: { 'application/json': { schema: { $ref: '#/components/schemas/SeatRequest' } } },
                    },
                    '400': { $ref: '#/components/responses/ValidationError' },
                    '401': { $ref: '#/components/responses/Unauthorized' },
                    '403': { $ref: '#/components/responses/Forbidden' },
                    '404': { $ref: '#/components/responses/NotFound' },
                },
            },
            delete: {
                tags: ['Seat Requests'],
                summary: 'Remover solicitação',
                description: 'O passageiro autor ou o motorista da viagem.',
                security: [{ bearerAuth: [] }],
                responses: {
                    '204': { $ref: '#/components/responses/NoContent' },
                    '401': { $ref: '#/components/responses/Unauthorized' },
                    '403': { $ref: '#/components/responses/Forbidden' },
                    '404': { $ref: '#/components/responses/NotFound' },
                },
            },
        },
    },
} as const;
