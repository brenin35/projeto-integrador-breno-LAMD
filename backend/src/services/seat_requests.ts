import { eq } from "drizzle-orm";
import { db } from "../config/index.js";
import { seatRequests } from "../models/seat_requests.sql.js";
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

    async delete(id: string) {
        const [result] = await db.delete(seatRequests).where(eq(seatRequests.id, id)).returning();
        return result;
    }
}