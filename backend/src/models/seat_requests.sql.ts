import { pgTable, uuid, integer, text, timestamp, pgEnum, unique } from "drizzle-orm/pg-core";
import { trips } from "./trips.sql.js";
import { users } from "./users.sql.js";

export const seatRequestStatusEnum = pgEnum('seat_request_status', ['pending', 'accepted', 'rejected', 'cancelled']);

export const seatRequests = pgTable('seat_requests', {
    id: uuid('id').primaryKey().defaultRandom(),
    tripId: uuid('trip_id').notNull().references(() => trips.id, { onDelete: 'cascade' }),
    passengerId: uuid('passenger_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
    seats: integer('seats').notNull().default(1),
    message: text('message'),
    status: seatRequestStatusEnum('status').notNull().default('pending'),
    respondedAt: timestamp('responded_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow()
}, (t) => [
    unique('unique_active_request').on(t.tripId, t.passengerId)
]);
