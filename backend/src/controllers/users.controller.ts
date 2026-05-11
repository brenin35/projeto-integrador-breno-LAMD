import { Router } from "express";
import { z } from "zod";
import { usersService } from "../services/users.js";

export const router = Router();

const userSchema = z.object({
    name: z.string().max(120),
    email: z.email().max(200),
    phone: z.string().max(20).optional(),
    role: z.enum(['passenger', 'driver']),
    vehicle: z.string().max(120).optional(),
});

router.post('/', async (req, res, next) => {
    try {
        const body = userSchema.parse(req.body);
        const result = await usersService.create(body);
        res.status(201).json(result);
    } catch (e: any) {
        if (e.errors) {
            res.status(400).json(e.errors);
        } else if (e.code === '23505') {
            res.status(409).json({ error: 'E-mail já cadastrado' });
        } else {
            next(e);
        }
    }
});

router.get('/', async (req, res, next) => {
    try {
        const result = await usersService.findAll();
        res.json(result);
    } catch (e) {
        next(e);
    }
});

router.get('/:id', async (req, res, next) => {
    try {
        const result = await usersService.findById(req.params.id);
        if (!result) {
            res.status(404).json({ error: 'User not found' });
            return;
        }
        res.json(result);
    } catch (e) {
        next(e);
    }
});

router.put('/:id', async (req, res, next) => {
    try {
        const body = userSchema.partial().parse(req.body);
        const result = await usersService.update(req.params.id, body as any);
        res.json(result);
    } catch (e: any) {
        if (e.errors) {
            res.status(400).json(e.errors);
        } else if (e.code === '23505') {
            res.status(409).json({ error: 'E-mail já cadastrado' });
        } else {
            next(e);
        }
    }
});

router.delete('/:id', async (req, res, next) => {
    try {
        await usersService.delete(req.params.id);
        res.status(204).end();
    } catch (e) {
        next(e);
    }
});