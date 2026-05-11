import { pgTable, uuid, varchar, numeric, timestamp, pgEnum } from "drizzle-orm/pg-core";

export const userRoleEnum = pgEnum('user_role', ['passenger', 'driver']);

export const users = pgTable('users', {
    id: uuid('id').primaryKey().defaultRandom(),
    name: varchar('name', { length: 120 }).notNull(),
    email: varchar('email', { length: 200 }).notNull().unique(),
    phone: varchar('phone', { length: 20 }),
    role: userRoleEnum('role').notNull(),
    vehicle: varchar('vehicle', { length: 120 }),
    rating: numeric('rating', { precision: 3, scale: 2 }).default('5.0'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow()
});

export type User = typeof users.$inferSelect;
export type InsertUser = typeof users.$inferInsert;