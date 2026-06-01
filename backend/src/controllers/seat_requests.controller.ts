import { Router } from "express";
import { z } from "zod";
import { seatRequestsService } from "../services/seat_requests.js";
import { tripsService } from "../services/trips.js";
import { authenticate } from "../auth/middleware.js";

export const router = Router();

const createSeatRequestSchema = z.object({
    tripId: z.string().uuid(),
    seats: z.number().int().min(1).optional(),
    message: z.string().optional(),
});

const updateSeatRequestSchema = z.object({
    status: z.enum(['pending', 'accepted', 'rejected', 'cancelled']).optional(),
    seats: z.number().int().min(1).optional(),
    message: z.string().optional(),
});

router.post('/', authenticate, async (req, res, next) => {
    try {
        const userId = req.user?.sub;
        if (!userId) {
            res.status(401).json({ error: 'Não autenticado' });
            return;
        }
        const body = createSeatRequestSchema.parse(req.body);
        const trip = await tripsService.findById(body.tripId);
        if (!trip) {
            res.status(400).json({ error: 'tripId não corresponde a uma viagem existente' });
            return;
        }
        if (trip.driverId === userId) {
            res.status(400).json({ error: 'Você não pode solicitar vaga na sua própria viagem' });
            return;
        }
        const result = await seatRequestsService.create({
            ...body,
            passengerId: userId,
            status: 'pending',
        });
        res.status(201).json(result);
    } catch (e: any) {
        if (e.errors) {
            res.status(400).json(e.errors);
        } else if (e.code === '23503') {
            res.status(400).json({ error: 'tripId não corresponde a um registro existente' });
        } else if (e.code === '23505') {
            res.status(409).json({ error: 'Você já tem uma solicitação para essa viagem' });
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

router.put('/:id', authenticate, async (req, res, next) => {
    try {
        const userId = req.user?.sub;
        if (!userId) {
            res.status(401).json({ error: 'Não autenticado' });
            return;
        }

        if (!req.params.id || typeof req.params.id !== 'string') {
            res.status(400).json({ error: 'ID da solicitação é obrigatório' });
            return;
        }

        const seatRequest = await seatRequestsService.findById(req.params.id);
        if (!seatRequest) {
            res.status(404).json({ error: 'Seat Request not found' });
            return;
        }
        const trip = await tripsService.findById(seatRequest.tripId);
        if (!trip || trip.driverId !== userId) {
            res.status(403).json({ error: 'Apenas o motorista da viagem pode responder a esta solicitação' });
            return;
        }
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

router.delete('/:id', authenticate, async (req, res, next) => {
    try {
        const userId = req.user?.sub;
        if (!userId) {
            res.status(401).json({ error: 'Não autenticado' });
            return;
        }

        if (!req.params.id || typeof req.params.id !== 'string') {
            res.status(400).json({ error: 'ID da solicitação é obrigatório' });
            return;
        }

        const seatRequest = await seatRequestsService.findById(req.params.id);
        if (!seatRequest) {
            res.status(404).json({ error: 'Seat Request not found' });
            return;
        }
        let allowed = seatRequest.passengerId === userId;
        if (!allowed) {
            const trip = await tripsService.findById(seatRequest.tripId);
            allowed = !!trip && trip.driverId === userId;
        }
        if (!allowed) {
            res.status(403).json({ error: 'Apenas o passageiro autor ou o motorista da viagem podem remover a solicitação' });
            return;
        }
        await seatRequestsService.delete(req.params.id);
        res.status(204).end();
    } catch (e) {
        next(e);
    }
});
