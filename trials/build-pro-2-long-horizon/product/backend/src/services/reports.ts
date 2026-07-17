import db from '../database';
export function getTicketMetrics(orgId: string) {
  const total = (db.prepare("SELECT COUNT(*) as c FROM tickets t JOIN projects p ON t.project_id=p.id WHERE p.organization_id=?").get(orgId) as any).c;
  const byStatus = db.prepare("SELECT t.status, COUNT(*) as c FROM tickets t JOIN projects p ON t.project_id=p.id WHERE p.organization_id=? GROUP BY t.status").all(orgId);
  const byPriority = db.prepare("SELECT t.priority, COUNT(*) as c FROM tickets t JOIN projects p ON t.project_id=p.id WHERE p.organization_id=? GROUP BY t.priority").all(orgId);
  return { total, byStatus, byPriority };
}
export function getTaskMetrics(orgId: string) {
  const total = (db.prepare("SELECT COUNT(*) as c FROM tasks t JOIN projects p ON t.project_id=p.id WHERE p.organization_id=?").get(orgId) as any).c;
  const byStatus = db.prepare("SELECT t.status, COUNT(*) as c FROM tasks t JOIN projects p ON t.project_id=p.id WHERE p.organization_id=? GROUP BY t.status").all(orgId);
  return { total, byStatus };
}
export function getAuditLog(orgId: string, limit=50) {
  return db.prepare("SELECT a.* FROM audit_log a LIMIT ?").all(limit);
}
