import { type User } from '../models/users.sql.js';

export type PublicUser = Omit<User, 'passwordHash'>;

export function sanitizeUser(user: User): PublicUser {
    const { passwordHash: _passwordHash, ...rest } = user;
    return rest;
}
