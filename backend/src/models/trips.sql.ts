import { pgTable, uuid, varchar, timestamp, integer, numeric, text, pgEnum } from "drizzle-orm/pg-core";
import { users } from "./users.sql.js";

export const tripStatusEnum = pgEnum('trip_status', ['open', 'full', 'started', 'completed', 'cancelled']);

export const trips = pgTable('trips', {
    id: uuid('id').primaryKey().defaultRandom(),
    driverId: uuid('driver_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
    origin: varchar('origin', { length: 300 }).notNull(),
    destination: varchar('destination', { length: 300 }).notNull(),
    departureAt: timestamp('departure_at', { withTimezone: true }).notNull(),
    totalSeats: integer('total_seats').notNull(),
    availableSeats: integer('available_seats').notNull(),
    pricePerSeat: numeric('price_per_seat', { precision: 8, scale: 2 }).notNull(),
    notes: text('notes'),
    status: tripStatusEnum('status').notNull().default('open'),
    startedAt: timestamp('started_at', { withTimezone: true }),
    completedAt: timestamp('completed_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow()
});

export type Trip = typeof trips.$inferSelect;
export type InsertTrip = typeof trips.$inferInsert;