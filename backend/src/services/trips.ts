import { eq } from "drizzle-orm";
import { db } from "../config/index.js";
import { trips } from "../models/trips.sql.js";

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
        const [result] = await db.update(trips).set({ ...data, updatedAt: new Date() }).where(eq(trips.id, id)).returning();
        return result;
    },

    async delete(id: string) {
        const [result] = await db.delete(trips).where(eq(trips.id, id)).returning();
        return result;
    }
}