import jwt, { type SignOptions } from 'jsonwebtoken';

const SECRET = process.env.JWT_SECRET ?? 'dev-secret-change-me';
const EXPIRES_IN = process.env.JWT_EXPIRES_IN ?? '7d';

/** Conteúdo (claims) do token: apenas o id do usuário. O papel é definido pelo contexto. */
export interface JwtPayload {
    sub: string;
}

export function signToken(payload: JwtPayload): string {
    const options: SignOptions = { expiresIn: EXPIRES_IN as NonNullable<SignOptions['expiresIn']> };
    return jwt.sign(payload, SECRET, options);
}

export function verifyToken(token: string): JwtPayload {
    return jwt.verify(token, SECRET) as JwtPayload;
}
