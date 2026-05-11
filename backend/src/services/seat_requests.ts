import { eq } from "drizzle-orm";
import { db } from "../config/index.js";
import { seatRequests } from "../models/seat_requests.sql.js";

export const seatRequestsService = {
    async create(data: typeof seatRequests.$inferInsert) {
        const [result] = await db.insert(seatRequests).values(data).returning();
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
        const [result] = await db.update(seatRequests).set({ ...data, updatedAt: new Date() }).where(eq(seatRequests.id, id)).returning();
        return result;
    },

    async delete(id: string) {
        const [result] = await db.delete(seatRequests).where(eq(seatRequests.id, id)).returning();
        return result;
    }
}