import db from '../database';
import { v4 as uuid } from 'uuid';
export function createApproval(data: any) {
  const id = uuid();
  db.prepare('INSERT INTO approvals (id,ticket_id,type,status,requested_by_id,created_at,updated_at) VALUES (?,?,?,?,?,datetime(\'now\'),datetime(\'now\'))')
    .run(id, data.ticketId, data.type, 'pending', data.requestedById);
  return db.prepare('SELECT * FROM approvals WHERE id = ?').get(id);
}
export function updateApproval(id: string, data: any) {
  db.prepare('UPDATE approvals SET status=?,approved_by_id=?,comment=?,updated_at=datetime(\'now\') WHERE id=?')
    .run(data.status, data.approvedById||null, data.comment||null, id);
  return db.prepare('SELECT * FROM approvals WHERE id = ?').get(id);
}
export function listApprovals(ticketId: string) { return db.prepare('SELECT * FROM approvals WHERE ticket_id = ?').all(ticketId); }
