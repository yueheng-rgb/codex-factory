import { initializeDatabase } from '../src/database';
import * as tasks from '../src/services/tasks';

beforeAll(() => initializeDatabase());

describe('Task Service', () => {
  let taskId: string;
  const projectId = 'test-project-1';
  it('should create a task', () => {
    const t = tasks.createTask({ title: 'Test Task', projectId, priority: 'high' }) as any;
    expect(t.title).toBe('Test Task'); expect(t.priority).toBe('high'); taskId = t.id;
  });
  it('should list tasks by project', () => {
    const list = tasks.listTasks(projectId) as any[];
    expect(list.length).toBeGreaterThanOrEqual(1);
  });
  it('should update task status', () => {
    const updated = tasks.updateTask(taskId, { title: 'Test Task', status: 'in_progress', priority: 'high' }) as any;
    expect(updated.status).toBe('in_progress');
  });
});
