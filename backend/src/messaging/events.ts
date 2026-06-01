export const EVENTS = {
    /** Passageiro criou uma nova solicitação de vaga. Consumido para notificar o motorista. */
    SEAT_REQUEST_CREATED: 'seat_request.created',
    /** Status de uma solicitação mudou (accepted/rejected/cancelled). Notifica o passageiro. */
    SEAT_REQUEST_STATUS_CHANGED: 'seat_request.status_changed',
    /** Status de uma viagem mudou (started/completed/cancelled). Notifica passageiros aceitos. */
    TRIP_STATUS_CHANGED: 'trip.status_changed',
} as const;

export type EventName = (typeof EVENTS)[keyof typeof EVENTS];

export interface EventEnvelope<T = unknown> {
    event: EventName;
    occurredAt: string;
    data: T;
}
