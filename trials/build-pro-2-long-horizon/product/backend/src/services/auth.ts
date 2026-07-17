import db from './database';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuid } from 'uuid';
import { AuthPayload, UserRole } from './types';

const JWT_SECRET = process.env.JWT_SECRET || 'nexusdesk-dev-secret-change-in-production';
const TOKEN_EXPIRY = '24h';

export function hashPassword(password: string): string {
  return bcrypt.hashSync(password, 10);
}
export function comparePassword(password: string, hash: string): boolean {
  return bcrypt.compareSync(password, hash);
}
export function generateToken(payload: AuthPayload): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: TOKEN_EXPIRY });
}
export function verifyToken(token: string): AuthPayload {
  return jwt.verify(token, JWT_SECRET) as AuthPayload;
}

export function registerUser(email: string, name: string, password: string, role: UserRole = 'agent', organizationId?: string) {
  const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
  if (existing) throw new Error('Email already registered');
  const id = uuid();
  const hash = hashPassword(password);
  db.prepare('INSERT INTO users (id, email, name, password_hash, role, organization_id) VALUES (?,?,?,?,?,?)')
    .run(id, email, name, hash, role, organizationId || null);
  return { id, email, name, role };
}
export function loginUser(email: string, password: string) {
  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email) as any;
  if (!user || !comparePassword(password, user.password_hash)) throw new Error('Invalid credentials');
  const payload: AuthPayload = { userId: user.id, email: user.email, role: user.role, organizationId: user.organization_id };
  const token = generateToken(payload);
  return { token, user: { id: user.id, email: user.email, name: user.name, role: user.role } };
}
