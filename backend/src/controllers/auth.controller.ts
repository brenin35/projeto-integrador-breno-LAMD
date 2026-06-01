import { Router } from "express";
import { z } from "zod";
import { usersService } from "../services/users.js";
import { hashPassword, verifyPassword } from "../auth/password.js";
import { signToken } from "../auth/jwt.js";
import { sanitizeUser } from "../auth/sanitize.js";

export const router = Router();

const registerSchema = z.object({
    name: z.string().max(120),
    email: z.email().max(200),
    password: z.string().min(6).max(72),
    phone: z.string().max(20).optional(),
    vehicle: z.string().max(120).optional(),
});

const loginSchema = z.object({
    email: z.email(),
    password: z.string().min(1),
});

router.post('/register', async (req, res, next) => {
    try {
        const { password, ...profile } = registerSchema.parse(req.body);
        const passwordHash = await hashPassword(password);
        const user = await usersService.create({ ...profile, passwordHash });
        if (!user) {
            res.status(500).json({ error: 'Falha ao criar usuário' });
            return;
        }
        const token = signToken({ sub: user.id });
        res.status(201).json({ token, user: sanitizeUser(user) });
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

router.post('/login', async (req, res, next) => {
    try {
        const body = loginSchema.parse(req.body);
        const user = await usersService.findByEmail(body.email);
        if (!user || !user.passwordHash || !(await verifyPassword(body.password, user.passwordHash))) {
            res.status(401).json({ error: 'Credenciais inválidas' });
            return;
        }
        const token = signToken({ sub: user.id });
        res.json({ token, user: sanitizeUser(user) });
    } catch (e: any) {
        if (e.errors) {
            res.status(400).json(e.errors);
        } else {
            next(e);
        }
    }
});
