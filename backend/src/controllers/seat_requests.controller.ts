import { Router } from "express";
import { z } from "zod";
import { seatRequestsService } from "../services/seat_requests.js";

export const router = Router();

const createSeatRequestSchema = z.object({
    tripId: z.string().uuid(),
    passengerId: z.string().uuid(),
    seats: z.number().int().min(1).optional(),
    message: z.string().optional(),
});

const updateSeatRequestSchema = z.object({
    status: z.enum(['pending', 'accepted', 'rejected', 'cancelled']).optional(),
    seats: z.number().int().min(1).optional(),
    message: z.string().optional(),
});

router.post('/', async (req, res, next) => {
    try {
        const body = createSeatRequestSchema.parse(req.body);
        const result = await seatRequestsService.create({
            ...body,
            status: 'pending',
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
        const result = await seatRequestsService.findAll();
        res.json(result);
    } catch (e) {
        next(e);
    }
});

router.get('/:id', async (req, res, next) => {
    try {
        const result = await seatRequestsService.findById(req.params.id);
        if (!result) {
            res.status(404).json({ error: 'Seat Request not found' });
            return;
        }
        res.json(result);
    } catch (e) {
        next(e);
    }
});

router.put('/:id', async (req, res, next) => {
    try {
        const body = updateSeatRequestSchema.parse(req.body);
        const result = await seatRequestsService.update(req.params.id, body as any);
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
        await seatRequestsService.delete(req.params.id);
        res.status(204).end();
    } catch (e) {
        next(e);
    }
});