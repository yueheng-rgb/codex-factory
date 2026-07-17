import db from '../database';
import { v4 as uuid } from 'uuid';
export function listClients(orgId: string) { return db.prepare('SELECT * FROM clients WHERE organization_id = ?').all(orgId); }
export function getClient(id: string) { return db.prepare('SELECT * FROM clients WHERE id = ?').get(id); }
export function createClient(data: any) {
  const id = uuid();
  db.prepare('INSERT INTO clients (id,name,email,phone,organization_id,created_at,updated_at) VALUES (?,?,?,?,?,datetime(\'now\'),datetime(\'now\'))')
    .run(id, data.name, data.email, data.phone || null, data.organizationId);
  return getClient(id);
}
export function updateClient(id: string, data: any) {
  db.prepare('UPDATE clients SET name=?,email=?,phone=?,updated_at=datetime(\'now\') WHERE id=?')
    .run(data.name, data.email, data.phone, id);
  return getClient(id);
}
export function deleteClient(id: string) { db.prepare('DELETE FROM clients WHERE id = ?').run(id); }
