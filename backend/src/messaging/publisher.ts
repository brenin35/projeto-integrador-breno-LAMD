import { getChannel, EXCHANGE } from './connection.js';
import { type EventName, type EventEnvelope } from './events.js';

export async function publishEvent<T>(event: EventName, data: T): Promise<void> {
    try {
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
        console.log(`[publisher] evento publicado: ${event}`);
    } catch (error) {
        console.error(`[publisher] falha ao publicar "${event}":`, (error as Error).message);
    }
}