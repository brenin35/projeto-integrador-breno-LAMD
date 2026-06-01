import 'dotenv/config';
import { connect, type ChannelModel, type Channel } from 'amqplib';

const RABBITMQ_URL = process.env.RABBITMQ_URL ?? 'amqp://guest:guest@localhost:5672';

export const EXCHANGE = 'caronascar.events';
export const EXCHANGE_TYPE = 'topic';

let modelPromise: Promise<ChannelModel> | null = null;
let channelPromise: Promise<Channel> | null = null;

async function openModel(): Promise<ChannelModel> {
    const model = await connect(RABBITMQ_URL);
    console.log(`[rabbitmq] conectado em ${RABBITMQ_URL}`);

    model.on('error', (err) => {
        console.error('[rabbitmq] erro na conexão:', err.message);
    });
    model.on('close', () => {
        console.warn('[rabbitmq] conexão encerrada — será reaberta sob demanda');
        modelPromise = null;
        channelPromise = null;
    });

    return model;
}

function getModel(): Promise<ChannelModel> {
    if (!modelPromise) {
        modelPromise = openModel().catch((err) => {
            modelPromise = null;
            throw err;
        });
    }
    return modelPromise;
}

export function getChannel(): Promise<Channel> {
    if (!channelPromise) {
        channelPromise = (async () => {
            const model = await getModel();
            const channel = await model.createChannel();
            await channel.assertExchange(EXCHANGE, EXCHANGE_TYPE, { durable: true });

            channel.on('error', (err) => {
                console.error('[rabbitmq] erro no canal:', err.message);
            });
            channel.on('close', () => {
                channelPromise = null;
            });

            return channel;
        })().catch((err) => {
            channelPromise = null;
            throw err;
        });
    }
    return channelPromise;
}

export async function closeConnection(): Promise<void> {
    const current = modelPromise;
    modelPromise = null;
    channelPromise = null;
    if (current) {
        const model = await current;
        await model.close();
    }
}
