import db from '../database';
import { v4 as uuid } from 'uuid';
export function listProjects(orgId: string) { return db.prepare('SELECT * FROM projects WHERE organization_id = ?').all(orgId); }
export function getProject(id: string) { return db.prepare('SELECT * FROM projects WHERE id = ?').get(id); }
export function createProject(data: any) {
  const id = uuid();
  db.prepare('INSERT INTO projects (id,name,description,status,organization_id,lead_id,created_at,updated_at) VALUES (?,?,?,?,?,?,datetime(\'now\'),datetime(\'now\'))')
    .run(id, data.name, data.description || null, 'active', data.organizationId, data.leadId);
  return getProject(id);
}
export function updateProject(id: string, data: any) {
  db.prepare('UPDATE projects SET name=?,description=?,updated_at=datetime(\'now\') WHERE id=?').run(data.name, data.description, id);
  return getProject(id);
}
