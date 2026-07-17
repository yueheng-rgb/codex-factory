import { initializeDatabase } from '../src/database';
import * as clients from '../src/services/clients';

beforeAll(() => initializeDatabase());

describe('Client Service', () => {
  let clientId: string;
  const orgId = 'test-org-1';
  it('should create a client', () => {
    const c = clients.createClient({ name: 'Acme Corp', email: 'acme@test.com', phone: '555-0100', organizationId: orgId }) as any;
    expect(c.name).toBe('Acme Corp'); clientId = c.id;
  });
  it('should list clients by org', () => {
    const list = clients.listClients(orgId) as any[];
    expect(list.length).toBeGreaterThanOrEqual(1);
  });
  it('should update a client', () => {
    const updated = clients.updateClient(clientId, { name: 'Acme Updated', email: 'acme2@test.com', phone: '555-0200' }) as any;
    expect(updated.name).toBe('Acme Updated');
  });
  it('should delete a client', () => {
    clients.deleteClient(clientId);
    const c = clients.getClient(clientId);
    expect(c).toBeUndefined();
  });
});
