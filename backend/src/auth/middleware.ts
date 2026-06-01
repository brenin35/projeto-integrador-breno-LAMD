import { type Request, type Response, type NextFunction } from 'express';
import { verifyToken, type JwtPayload } from './jwt.js';
declare global {
    // eslint-disable-next-line @typescript-eslint/no-namespace
    namespace Express {
        interface Request {
            user?: JwtPayload;
        }
    }
}

export function authenticate(req: Request, res: Response, next: NextFunction): void {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
        res.status(401).json({ error: 'Token ausente. Envie o cabeçalho Authorization: Bearer <token>' });
        return;
    }
    try {
        req.user = verifyToken(header.slice('Bearer '.length));
        next();
    } catch {
        res.status(401).json({ error: 'Token inválido ou expirado' });
    }
}
