import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

export default function Layout({ children }: { children: React.ReactNode }) {
  const { auth, logout } = useAuth();
  const nav = useNavigate();
  return (
    <div className="layout">
      <aside className="sidebar">
        <h2>NexusDesk</h2>
        <nav>
          <Link to="/">Dashboard</Link>
          <Link to="/clients">Clients</Link>
          <Link to="/projects">Projects</Link>
        </nav>
      </aside>
      <div style={{flex:1}}>
        <header className="header">
          <span>{auth?.user?.name} ({auth?.user?.role})</span>
          <button className="btn btn-secondary" onClick={() => { logout(); nav('/login'); }}>Logout</button>
        </header>
        <main className="main">{children}</main>
      </div>
    </div>
  );
}
