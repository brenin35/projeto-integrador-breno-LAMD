import { getChannel, EXCHANGE } from './connection.js';
import { type EventName, type EventEnvelope } from './events.js';

export async function publishEvent<T>(event: EventName, data: T): Promise<void> {
    const channel = await getChannel();
    const envelope: EventEnvelope<T> = {
        event,
        occurredAt: new Date().toISOString(),
        data,
    };
    channel.publish(EXCHANGE, event, Buffer.from(JSON.stringify(envelope)), {
        persistent: true,
        contentType: 'application/json',
    });
}

export async function safePublish<T>(event: EventName, data: T): Promise<void> {
    try {
        await publishEvent(event, data);
        console.log(`[publisher] evento publicado: ${event}`);
    } catch (err) {
        console.error(`[publisher] falha ao publicar "${event}":`, (err as Error).message);
    }
}
