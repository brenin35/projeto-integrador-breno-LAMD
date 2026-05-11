import { Router } from "express";
import { z } from "zod";
import { tripsService } from "../services/trips.js";

export const router = Router();

const createTripSchema = z.object({
    driverId: z.uuid(),
    origin: z.string().max(300),
    destination: z.string().max(300),
    departureAt: z.iso.datetime().transform(str => new Date(str)),
    totalSeats: z.number().int().min(1).max(8),
    pricePerSeat: z.string(),
    notes: z.string().optional(),
});

const updateTripSchema = z.object({
    availableSeats: z.number().int().min(0).optional(),
    status: z.enum(['open', 'full', 'started', 'completed', 'cancelled']).optional(),
    notes: z.string().optional(),
});

router.post('/', async (req, res, next) => {
    try {
        const body = createTripSchema.parse(req.body);
        const result = await tripsService.create({
            ...body,
            availableSeats: body.totalSeats,
            status: 'open',
        });
        res.status(201).json(result);
    } catch (e: any) {
        if (e.errors) {
            res.status(400).json(e.errors);
        } else {
            next(e);
        }
    }
});

router.get('/', async (req, res, next) => {
    try {
        const result = await tripsService.findAll();
        res.json(result);
    } catch (e) {
        next(e);
    }
});

router.get('/:id', async (req, res, next) => {
    try {
        const result = await tripsService.findById(req.params.id);
        if (!result) {
            res.status(404).json({ error: 'Trip not found' });
            return;
        }
        res.json(result);
    } catch (e) {
        next(e);
    }
});

router.put('/:id', async (req, res, next) => {
    try {
        const body = updateTripSchema.parse(req.body);
        const result = await tripsService.update(req.params.id, body as any);
        res.json(result);
    } catch (e: any) {
        if (e.errors) {
            res.status(400).json(e.errors);
        } else {
            next(e);
        }
    }
});

router.delete('/:id', async (req, res, next) => {
    try {
        await tripsService.delete(req.params.id);
        res.status(204).end();
    } catch (e) {
        next(e);
    }
});