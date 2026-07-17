import db from '../database';
import { v4 as uuid } from 'uuid';
export function listRules(orgId: string) { return db.prepare('SELECT * FROM automation_rules WHERE organization_id = ?').all(orgId); }
export function createRule(data: any) {
  const id = uuid();
  db.prepare('INSERT INTO automation_rules (id,name,trigger_event,conditions,actions,enabled,organization_id,created_at,updated_at) VALUES (?,?,?,?,?,?,?,datetime(\'now\'),datetime(\'now\'))')
    .run(id, data.name, data.triggerEvent, JSON.stringify(data.conditions||{}), JSON.stringify(data.actions||[]), data.enabled!==false?1:0, data.organizationId);
  return db.prepare('SELECT * FROM automation_rules WHERE id = ?').get(id);
}
export function updateRule(id: string, data: any) {
  db.prepare('UPDATE automation_rules SET name=?,trigger_event=?,conditions=?,actions=?,enabled=?,updated_at=datetime(\'now\') WHERE id=?')
    .run(data.name, data.triggerEvent, JSON.stringify(data.conditions||{}), JSON.stringify(data.actions||[]), data.enabled!==false?1:0, id);
  return db.prepare('SELECT * FROM automation_rules WHERE id = ?').get(id);
}
export function getMatchingRules(triggerEvent: string) {
  return db.prepare('SELECT * FROM automation_rules WHERE trigger_event = ? AND enabled = 1').all(triggerEvent);
}
