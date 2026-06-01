export const EVENTS = {
    SEAT_REQUEST_CREATED: 'seat_request.created',
    SEAT_REQUEST_STATUS_CHANGED: 'seat_request.status_changed',
    TRIP_STATUS_CHANGED: 'trip.status_changed',
} as const;

export type EventName = (typeof EVENTS)[keyof typeof EVENTS];

export interface EventEnvelope<T = unknown> {
    event: EventName;
    occurredAt: string;
    data: T;
}
