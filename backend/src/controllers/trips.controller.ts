import { Router, type Request, type Response } from "express";
import { z } from "zod";
import { tripsService } from "../services/trips.js";
import { authenticate } from "../auth/middleware.js";

export const router = Router();

const createTripSchema = z.object({
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

async function ensureTripOwner(req: Request, res: Response): Promise<boolean> {
    const userId = req.user?.sub;
    if (!userId) {
        res.status(401).json({ error: 'Não autenticado' });
        return false;
    }

    if (!req.params.id || typeof req.params.id !== 'string') {
        res.status(400).json({ error: 'ID da viagem é obrigatório' });
        return false;
    }

    const trip = await tripsService.findById(req.params.id);
    if (!trip) {
        res.status(404).json({ error: 'Trip not found' });
        return false;
    }
    if (trip.driverId !== userId) {
        res.status(403).json({ error: 'Apenas o motorista dono da viagem pode alterá-la' });
        return false;
    }
    return true;
}

router.post('/', authenticate, async (req, res, next) => {
    try {
        const body = createTripSchema.parse(req.body);
        const result = await tripsService.create({
            ...body,
            driverId: req.user!.sub,
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

router.put('/:id', authenticate, async (req, res, next) => {
    try {
        if (!(await ensureTripOwner(req, res))) return;

        if (!req.params.id || typeof req.params.id !== 'string') {
            res.status(400).json({ error: 'ID da viagem é obrigatório' });
            return;
        }
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

router.delete('/:id', authenticate, async (req, res, next) => {
    try {
        if (!req.params.id || typeof req.params.id !== 'string') {
            res.status(400).json({ error: 'ID da viagem é obrigatório' });
            return;
        }
        
        if (!(await ensureTripOwner(req, res))) return;
        await tripsService.delete(req.params.id);
        res.status(204).end();
    } catch (e) {
        next(e);
    }
});
