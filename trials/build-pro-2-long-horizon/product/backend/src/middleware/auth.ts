import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../services/auth';
import { UserRole } from '../types';

declare global { namespace Express { interface Request { user?: any; } } }

export function authenticate(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) return res.status(401).json({ success: false, error: 'No token' });
  try {
    req.user = verifyToken(header.slice(7));
    next();
  } catch { return res.status(401).json({ success: false, error: 'Invalid token' }); }
}
export function authorize(...roles: UserRole[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user || !roles.includes(req.user.role)) return res.status(403).json({ success: false, error: 'Forbidden' });
    next();
  };
}
export function auditLog(req: Request, action: string, entityType: string, entityId: string, changes: string = '{}') {
  const db = require('../database').default;
  const { v4: uuid } = require('uuid');
  db.prepare('INSERT INTO audit_log (id, user_id, action, entity_type, entity_id, changes, created_at) VALUES (?,?,?,?,?,?,datetime(\'now\'))')
    .run(uuid(), req.user?.userId || 'system', action, entityType, entityId, changes);
}
