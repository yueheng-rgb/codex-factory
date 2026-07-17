import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

export default function Login() {
  const [email, setEmail] = useState(''); const [password, setPassword] = useState('');
  const [error, setError] = useState(''); const [loading, setLoading] = useState(false);
  const { login } = useAuth(); const nav = useNavigate();
  const handle = async (e: React.FormEvent) => { e.preventDefault(); setError(''); setLoading(true);
    try { await login(email, password); nav('/'); } catch (err: any) { setError(err.message); } finally { setLoading(false); } };
  return (
    <div className="login-container">
      <h1>NexusDesk Login</h1>
      <form onSubmit={handle}><div className="form-group"><label>Email</label><input type="email" value={email} onChange={e=>setEmail(e.target.value)} required /></div>
        <div className="form-group"><label>Password</label><input type="password" value={password} onChange={e=>setPassword(e.target.value)} required /></div>
        {error && <div className="error">{error}</div>}
        <button className="btn btn-primary" style={{width:'100%',marginTop:8}} disabled={loading}>{loading?'Logging in...':'Login'}</button>
      </form>
      <p style={{textAlign:'center',marginTop:16,fontSize:14}}>No account? <Link to="/register">Register</Link></p>
    </div>
  );
}
