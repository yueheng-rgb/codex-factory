import { useEffect, useState } from 'react';
import { projectApi, clientApi } from '../services/api';

export default function Dashboard() {
  const [stats, setStats] = useState({ projects: 0, clients: 0, tasks: 0 });
  useEffect(() => { Promise.all([projectApi.list(), clientApi.list()]).then(([p, c]) => setStats({ projects: p.data?.length || 0, clients: c.data?.length || 0, tasks: 0 })).catch(()=>{}); }, []);
  return (<div>
    <h2>Dashboard</h2>
    <div className="dashboard-grid">
      <div className="stat-card"><div className="value">{stats.projects}</div><div className="label">Projects</div></div>
      <div className="stat-card"><div className="value">{stats.clients}</div><div className="label">Clients</div></div>
      <div className="stat-card"><div className="value">{stats.tasks}</div><div className="label">Tasks</div></div>
    </div>
  </div>);
}
