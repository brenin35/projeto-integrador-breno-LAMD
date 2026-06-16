import { eq, and } from "drizzle-orm";
import { db } from "../config/index.js";
import { seatRequests } from "../models/seat_requests.sql.js";
import { tripsService } from "./trips.js";
import { publishEvent } from "../messaging/publisher.js";
import { EVENTS } from "../messaging/events.js";

export const seatRequestsService = {
    async create(data: typeof seatRequests.$inferInsert) {
        const [result] = await db.insert(seatRequests).values(data).returning();
        if (result) {
            await publishEvent(EVENTS.SEAT_REQUEST_CREATED, {
                id: result.id,
                tripId: result.tripId,
                passengerId: result.passengerId,
                seats: result.seats,
                status: result.status,
            });
        }
        return result;
    },

    async findAll() {
        return db.select().from(seatRequests);
    },

    async findById(id: string) {
        const [result] = await db.select().from(seatRequests).where(eq(seatRequests.id, id));
        return result;
    },

    async findByTripAndPassenger(tripId: string, passengerId: string) {
        const [result] = await db.select().from(seatRequests)
            .where(and(eq(seatRequests.tripId, tripId), eq(seatRequests.passengerId, passengerId)));
        return result;
    },

    async reactivate(id: string, data: { seats?: number | undefined; message?: string | null | undefined }) {
        const [result] = await db.update(seatRequests).set({
            status: 'pending',
            seats: data.seats ?? 1,
            message: data.message ?? null,
            respondedAt: null,
            updatedAt: new Date(),
        }).where(eq(seatRequests.id, id)).returning();
        if (result) {
            await publishEvent(EVENTS.SEAT_REQUEST_CREATED, {
                id: result.id,
                tripId: result.tripId,
                passengerId: result.passengerId,
                seats: result.seats,
                status: result.status,
            });
        }
        return result;
    },

    async update(id: string, data: Partial<typeof seatRequests.$inferInsert>) {
        const before = await this.findById(id);
        const [result] = await db.update(seatRequests).set({ ...data, updatedAt: new Date() }).where(eq(seatRequests.id, id)).returning();
        if (result && before && data.status && before.status !== result.status) {
            await publishEvent(EVENTS.SEAT_REQUEST_STATUS_CHANGED, {
                id: result.id,
                tripId: result.tripId,
                passengerId: result.passengerId,
                previousStatus: before.status,
                status: result.status,
            });
        }
        return result;
    },

    /** Motorista responde a solicitação (aceitar/recusar): grava o status e o
     *  momento da resposta. Aceitar reserva vagas na viagem. */
    async respond(id: string, status: 'accepted' | 'rejected') {
        const before = await this.findById(id);
        if (status === 'accepted' && before) {
            await this.reserveSeats(before.tripId, before.seats);
        }
        return this.update(id, { status, respondedAt: new Date() });
    },


    async cancel(id: string) {
        const before = await this.findById(id);
        const result = await this.update(id, { status: 'cancelled' });
        if (before && before.status === 'accepted') {
            await this.releaseSeats(before.tripId, before.seats);
        }
        return result;
    },

    async reserveSeats(tripId: string, seats: number) {
        const trip = await tripsService.findById(tripId);
        if (!trip) return;
        const remaining = Math.max(0, trip.availableSeats - seats);
        await tripsService.update(tripId, {
            availableSeats: remaining,
            status: remaining === 0 ? 'full' : trip.status,
        });
    },

    async releaseSeats(tripId: string, seats: number) {
        const trip = await tripsService.findById(tripId);
        if (!trip) return;
        const remaining = Math.min(trip.totalSeats, trip.availableSeats + seats);
        const status = trip.status === 'full' && remaining > 0 ? 'open' : trip.status;
        await tripsService.update(tripId, { availableSeats: remaining, status });
    },

    async delete(id: string) {
        const [result] = await db.delete(seatRequests).where(eq(seatRequests.id, id)).returning();
        return result;
    }
}