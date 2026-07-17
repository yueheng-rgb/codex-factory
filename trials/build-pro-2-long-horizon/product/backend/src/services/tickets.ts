import db from '../database';
import { v4 as uuid } from 'uuid';
export function listTickets(projectId: string) { return db.prepare('SELECT * FROM tickets WHERE project_id = ?').all(projectId); }
export function getTicket(id: string) { return db.prepare('SELECT * FROM tickets WHERE id = ?').get(id); }
export function createTicket(data: any) {
  const id = uuid();
  db.prepare('INSERT INTO tickets (id,title,description,status,priority,project_id,assignee_id,client_id,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,datetime(\'now\'),datetime(\'now\'))')
    .run(id, data.title, data.description||null, 'new', data.priority||'medium', data.projectId, data.assigneeId||null, data.clientId||null);
  return getTicket(id);
}
const VALID_TRANSITIONS: Record<string, string[]> = {
  'new': ['triaged','closed'], 'triaged': ['assigned','closed'], 'assigned': ['waiting_customer','resolved'],
  'waiting_customer': ['resolved','closed'], 'resolved': ['closed','reopened'], 'closed': ['reopened']
};
export function updateTicket(id: string, data: any) {
  const current = getTicket(id) as any;
  if (!current) throw new Error('Ticket not found');
  if (data.status && data.status !== current.status) {
    const allowed = VALID_TRANSITIONS[current.status] || [];
    if (!allowed.includes(data.status)) throw new Error(`Invalid transition: ${current.status} -> ${data.status}`);
  }
  db.prepare('UPDATE tickets SET title=?,description=?,status=?,priority=?,assignee_id=?,client_id=?,updated_at=datetime(\'now\') WHERE id=?')
    .run(data.title||current.title, data.description||current.description, data.status||current.status, data.priority||current.priority,
      data.assigneeId||current.assignee_id, data.clientId||current.client_id, id);
  return getTicket(id);
}
