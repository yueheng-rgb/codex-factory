import { registerUser, loginUser } from '../src/services/auth';
import { initializeDatabase } from '../src/database';

beforeAll(() => initializeDatabase());

describe('Auth Service', () => {
  const testEmail = `test-${Date.now()}@nexusdesk.com`;
  it('should register a new user', () => {
    const user = registerUser(testEmail, 'Test User', 'password123', 'agent');
    expect(user.email).toBe(testEmail);
    expect(user.name).toBe('Test User');
    expect(user.role).toBe('agent');
  });
  it('should reject duplicate email', () => {
    expect(() => registerUser(testEmail, 'Dup', 'pass', 'agent')).toThrow();
  });
  it('should login with correct credentials', () => {
    const result = loginUser(testEmail, 'password123');
    expect(result.token).toBeTruthy();
    expect(result.user.email).toBe(testEmail);
  });
  it('should reject wrong password', () => {
    expect(() => loginUser(testEmail, 'wrong')).toThrow();
  });
});
