import 'dotenv/config';
import { getChannel, closeConnection, EXCHANGE } from './connection.js';
import { EVENTS, type EventEnvelope } from './events.js';

const QUEUE = 'notifications';

interface SeatRequestEvent {
    id: string;
    tripId: string;
    passengerId: string;
    seats?: number;
    status: string;
    previousStatus?: string;
}

interface TripEvent {
    id: string;
    driverId: string;
    status: string;
    previousStatus?: string;
}

function handleEvent(envelope: EventEnvelope): void {
    switch (envelope.event) {
        case EVENTS.SEAT_REQUEST_CREATED: {
            const data = envelope.data as SeatRequestEvent;
            console.log(
                `🔔 [notificação → motorista] Nova solicitação de vaga ${data.id} ` +
                `na viagem ${data.tripId} (passageiro ${data.passengerId}, ${data.seats ?? 1} vaga(s)).`,
            );
            break;
        }
        case EVENTS.SEAT_REQUEST_STATUS_CHANGED: {
            const data = envelope.data as SeatRequestEvent;
            console.log(
                `🔔 [notificação → passageiro] Sua solicitação ${data.id} mudou de ` +
                `"${data.previousStatus}" para "${data.status}" na viagem ${data.tripId}.`,
            );
            break;
        }
        case EVENTS.TRIP_STATUS_CHANGED: {
            const data = envelope.data as TripEvent;
            console.log(
                `🔔 [notificação → passageiros] A viagem ${data.id} mudou de ` +
                `"${data.previousStatus}" para "${data.status}".`,
            );
            break;
        }
        default:
            console.warn(`[consumer] evento desconhecido: ${envelope.event}`);
    }
}

async function start(): Promise<void> {
    const channel = await getChannel();

    await channel.assertQueue(QUEUE, { durable: true });
    await channel.bindQueue(QUEUE, EXCHANGE, 'seat_request.*');
    await channel.bindQueue(QUEUE, EXCHANGE, EVENTS.TRIP_STATUS_CHANGED);
    await channel.prefetch(10);

    console.log(`[consumer] aguardando eventos na fila "${QUEUE}" (Ctrl+C para sair)...`);

    await channel.consume(QUEUE, (msg) => {
        if (!msg) return;
        try {
            const envelope = JSON.parse(msg.content.toString()) as EventEnvelope;
            handleEvent(envelope);
            channel.ack(msg);
        } catch (err) {
            console.error('[consumer] erro ao processar mensagem:', (err as Error).message);
            channel.nack(msg, false, false);
        }
    });
}

async function shutdown(): Promise<void> {
    console.log('\n[consumer] encerrando...');
    try {
        await closeConnection();
    } finally {
        process.exit(0);
    }
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

start().catch((err) => {
    console.error('[consumer] falha ao iniciar:', err);
    process.exit(1);
});
