import { eq } from "drizzle-orm";
import { db } from "../config/index.js";
import { trips } from "../models/trips.sql.js";
import { publishEvent } from "../messaging/publisher.js";
import { EVENTS } from "../messaging/events.js";

export const tripsService = {
    async create(data: typeof trips.$inferInsert) {
        const [result] = await db.insert(trips).values(data).returning();
        return result;
    },

    async findAll() {
        return db.select().from(trips);
    },

    async findById(id: string) {
        const [result] = await db.select().from(trips).where(eq(trips.id, id));
        return result;
    },

    async update(id: string, data: Partial<typeof trips.$inferInsert>) {
        const before = await this.findById(id);
        const [result] = await db.update(trips).set({ ...data, updatedAt: new Date() }).where(eq(trips.id, id)).returning();
        if (result && before && data.status && before.status !== result.status) {
            await publishEvent(EVENTS.TRIP_STATUS_CHANGED, {
                id: result.id,
                driverId: result.driverId,
                previousStatus: before.status,
                status: result.status,
            });
        }
        return result;
    },

    async delete(id: string) {
        const [result] = await db.delete(trips).where(eq(trips.id, id)).returning();
        return result;
    }
}