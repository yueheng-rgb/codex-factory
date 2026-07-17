import { initializeDatabase } from '../src/database';
import * as projects from '../src/services/projects';

beforeAll(() => initializeDatabase());

describe('Project Service', () => {
  let projectId: string;
  const orgId = 'test-org-1';
  it('should create a project', () => {
    const p = projects.createProject({ name: 'Test Project', description: 'A test', organizationId: orgId, leadId: 'lead-1' }) as any;
    expect(p.name).toBe('Test Project'); projectId = p.id;
  });
  it('should list projects by org', () => {
    const list = projects.listProjects(orgId) as any[];
    expect(list.length).toBeGreaterThanOrEqual(1);
  });
  it('should update a project', () => {
    const updated = projects.updateProject(projectId, { name: 'Updated Project', description: 'Updated' }) as any;
    expect(updated.name).toBe('Updated Project');
  });
});
