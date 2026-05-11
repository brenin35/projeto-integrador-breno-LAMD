import { eq } from "drizzle-orm";
import { db } from "../config/index.js";
import { users, type InsertUser } from "../models/users.sql.js";

export const usersService = {
    async create(data: typeof users.$inferInsert) {
        const [result] = await db.insert(users).values(data).returning();
        return result;
    },

    async findAll() {
        return db.select().from(users);
    },

    async findById(id: string) {
        const [result] = await db.select().from(users).where(eq(users.id, id));
        return result;
    },

    async update(id: string, data: Partial<InsertUser>) {
        const [result] = await db.update(users).set({ ...data, updatedAt: new Date() }).where(eq(users.id, id)).returning();
        return result;
    },

    async delete(id: string) {
        const [result] = await db.delete(users).where(eq(users.id, id)).returning();
        return result;
    }
}