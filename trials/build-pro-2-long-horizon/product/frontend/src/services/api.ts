const BASE = '/api';
async function request(path: string, options: RequestInit = {}) {
  const auth = JSON.parse(localStorage.getItem('nexusdesk_auth') || '{}');
  const headers: any = { 'Content-Type': 'application/json', ...options.headers };
  if (auth.token) headers['Authorization'] = `Bearer ${auth.token}`;
  const res = await fetch(`${BASE}${path}`, { ...options, headers });
  if (!res.ok) { const err = await res.json().catch(() => ({ error: 'Request failed' })); throw new Error(err.error || 'Request failed'); }
  return res.json();
}
export const authApi = {
  login: (email: string, password: string) => request('/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) }),
  register: (data: any) => request('/auth/register', { method: 'POST', body: JSON.stringify(data) }),
};
export const clientApi = {
  list: () => request('/clients'),
  create: (data: any) => request('/clients', { method: 'POST', body: JSON.stringify(data) }),
  update: (id: string, data: any) => request(`/clients/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  delete: (id: string) => request(`/clients/${id}`, { method: 'DELETE' }),
};
export const projectApi = {
  list: () => request('/projects'),
  create: (data: any) => request('/projects', { method: 'POST', body: JSON.stringify(data) }),
  update: (id: string, data: any) => request(`/projects/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
};
export const taskApi = {
  listByProject: (projectId: string) => request(`/tasks/project/${projectId}`),
  create: (data: any) => request('/tasks', { method: 'POST', body: JSON.stringify(data) }),
  update: (id: string, data: any) => request(`/tasks/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
};
