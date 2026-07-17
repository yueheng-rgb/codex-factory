import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

export default function Register() {
  const [form, setForm] = useState({ email:'',name:'',password:'',role:'agent' });
  const [error, setError] = useState(''); const [loading, setLoading] = useState(false);
  const { register } = useAuth(); const nav = useNavigate();
  const handle = async (e: React.FormEvent) => { e.preventDefault(); setError(''); setLoading(true);
    try { await register(form); nav('/login'); } catch (err: any) { setError(err.message); } finally { setLoading(false); } };
  return (
    <div className="login-container">
      <h1>Register</h1>
      <form onSubmit={handle}>
        <div className="form-group"><label>Name</label><input value={form.name} onChange={e=>setForm({...form,name:e.target.value})} required /></div>
        <div className="form-group"><label>Email</label><input type="email" value={form.email} onChange={e=>setForm({...form,email:e.target.value})} required /></div>
        <div className="form-group"><label>Password</label><input type="password" value={form.password} onChange={e=>setForm({...form,password:e.target.value})} required /></div>
        {error && <div className="error">{error}</div>}
        <button className="btn btn-primary" style={{width:'100%',marginTop:8}} disabled={loading}>Register</button>
      </form>
      <p style={{textAlign:'center',marginTop:16,fontSize:14}}>Have account? <Link to="/login">Login</Link></p>
    </div>
  );
}
