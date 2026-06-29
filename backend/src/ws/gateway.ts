import { WebSocketServer, type WebSocket } from 'ws';
import { type Server } from 'http';
import { verifyToken } from '../auth/jwt.js';
import { getChannel, EXCHANGE } from '../messaging/connection.js';
import { EVENTS, type EventEnvelope } from '../messaging/events.js';
import { tripsService } from '../services/trips.js';
import { seatRequestsService } from '../services/seat_requests.js';

/**
 * Gateway WebSocket — a "ponte" entre o MOM (RabbitMQ) e os apps Flutter.
 *
 * Roda DENTRO do processo da API. Ele:
 *  1. Aceita conexões WebSocket em /ws autenticadas por JWT (token na query).
 *  2. Consome os MESMOS eventos de domínio do RabbitMQ, por uma fila própria
 *     (`ws-gateway`) ligada ao topic exchange `caronascar.events`. Como é outra
 *     fila, ele recebe uma cópia dos eventos em paralelo ao worker `notifications`
 *     (fan-out pub/sub).
 *  3. Decide o destinatário de cada evento e empurra em tempo real para o socket
 *     daquele usuário — sem polling no app.
 */

const QUEUE = 'ws-gateway';

// userId -> conjunto de conexões abertas daquele usuário (pode ter várias).
const clients = new Map<string, Set<WebSocket>>();

function addClient(userId: string, ws: WebSocket): void {
    let set = clients.get(userId);
    if (!set) {
        set = new Set();
        clients.set(userId, set);
    }
    set.add(ws);
}

function removeClient(userId: string, ws: WebSocket): void {
    const set = clients.get(userId);
    if (!set) return;
    set.delete(ws);
    if (set.size === 0) clients.delete(userId);
}

function sendToUser(userId: string, type: string, data: unknown): void {
    const set = clients.get(userId);
    if (!set) return;
    const message = JSON.stringify({ type, data });
    for (const ws of set) {
        if (ws.readyState === ws.OPEN) ws.send(message);
    }
}

async function routeEvent(envelope: EventEnvelope): Promise<void> {
    const data = envelope.data as Record<string, any>;
    switch (envelope.event) {
        case EVENTS.SEAT_REQUEST_STATUS_CHANGED: {
            sendToUser(data.passengerId, envelope.event, data);
            const trip = await tripsService.findById(data.tripId);
            if (trip) sendToUser(trip.driverId, envelope.event, data);
            break;
        }
        case EVENTS.SEAT_REQUEST_CREATED: {
            const trip = await tripsService.findById(data.tripId);
            if (trip) sendToUser(trip.driverId, envelope.event, data);
            break;
        }
        case EVENTS.TRIP_STATUS_CHANGED: {
            sendToUser(data.driverId, envelope.event, data);
            const requests = await seatRequestsService.findAll();
            for (const r of requests) {
                if (r.tripId === data.id && r.status === 'accepted') {
                    sendToUser(r.passengerId, envelope.event, data);
                }
            }
            break;
        }
    }
}

async function startConsumer(): Promise<void> {
    const channel = await getChannel();
    await channel.assertQueue(QUEUE, { durable: true });
    await channel.bindQueue(QUEUE, EXCHANGE, 'seat_request.*');
    await channel.bindQueue(QUEUE, EXCHANGE, EVENTS.TRIP_STATUS_CHANGED);
    await channel.consume(QUEUE, async (msg) => {
        if (!msg) return;
        try {
            await routeEvent(JSON.parse(msg.content.toString()) as EventEnvelope);
            channel.ack(msg);
        } catch (err) {
            console.error('[ws] erro ao rotear evento:', (err as Error).message);
            channel.nack(msg, false, false);
        }
    });
}

export function startWsGateway(server: Server): void {
    const wss = new WebSocketServer({ server, path: '/ws' });

    wss.on('connection', (ws, req) => {
        const url = new URL(req.url ?? '', 'http://localhost');
        const token = url.searchParams.get('token');
        let userId: string;
        try {
            userId = verifyToken(token ?? '').sub;
        } catch {
            ws.close(4001, 'token inválido');
            return;
        }
        addClient(userId, ws);
        ws.send(JSON.stringify({ type: 'connected', data: { userId } }));
        ws.on('close', () => removeClient(userId, ws));
        ws.on('error', () => removeClient(userId, ws));
    });

    startConsumerWithRetry();
}

function startConsumerWithRetry(): void {
    startConsumer()
        .then(() => console.log('[ws] gateway WebSocket pronto em ws://localhost:3000/ws'))
        .catch((err) => {
            console.warn(`[ws] consumidor indisponível (${err.message || 'sem broker'}); nova tentativa em 5s`);
            setTimeout(startConsumerWithRetry, 5000);
        });
}
