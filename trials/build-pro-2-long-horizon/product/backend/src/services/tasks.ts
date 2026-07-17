import db from '../database';
import { v4 as uuid } from 'uuid';
export function listTasks(projectId: string) { return db.prepare('SELECT * FROM tasks WHERE project_id = ?').all(projectId); }
export function getTask(id: string) { return db.prepare('SELECT * FROM tasks WHERE id = ?').get(id); }
export function createTask(data: any) {
  const id = uuid();
  db.prepare('INSERT INTO tasks (id,title,description,status,priority,project_id,assignee_id,due_date,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,datetime(\'now\'),datetime(\'now\'))')
    .run(id, data.title, data.description || null, 'todo', data.priority || 'medium', data.projectId, data.assigneeId || null, data.dueDate || null);
  return getTask(id);
}
export function updateTask(id: string, data: any) {
  db.prepare('UPDATE tasks SET title=?,description=?,status=?,priority=?,assignee_id=?,due_date=?,updated_at=datetime(\'now\') WHERE id=?')
    .run(data.title, data.description, data.status, data.priority, data.assigneeId, data.dueDate, id);
  return getTask(id);
}
