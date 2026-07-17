import { useEffect, useState } from 'react';
import { clientApi } from '../services/api';

export default function Clients() {
  const [clients, setClients] = useState<any[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: '', email: '', phone: '' });
  const [editing, setEditing] = useState<string | null>(null);
  useEffect(() => { clientApi.list().then(r => setClients(r.data || [])).catch(()=>{}); }, []);
  const handleSubmit = async (e: React.FormEvent) => { e.preventDefault();
    try {
      if (editing) { await clientApi.update(editing, form); }
      else { await clientApi.create(form); }
      setShowForm(false); setEditing(null); setForm({ name: '', email: '', phone: '' });
      const r = await clientApi.list(); setClients(r.data || []);
    } catch (err: any) { alert(err.message); } };
  const handleDelete = async (id: string) => { if (!confirm('Delete?')) return;
    await clientApi.delete(id); const r = await clientApi.list(); setClients(r.data || []); };
  return (<div>
    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
      <h2>Clients</h2>
      <button className="btn btn-primary" onClick={()=>{setShowForm(!showForm);setEditing(null);setForm({name:'',email:'',phone:''});}}>
        {showForm ? 'Cancel' : '+ New Client'}</button>
    </div>
    {showForm && (<div className="card">
      <form onSubmit={handleSubmit}>
        <div className="form-group"><label>Name</label><input value={form.name} onChange={e=>setForm({...form,name:e.target.value})} required /></div>
        <div className="form-group"><label>Email</label><input type="email" value={form.email} onChange={e=>setForm({...form,email:e.target.value})} /></div>
        <div className="form-group"><label>Phone</label><input value={form.phone} onChange={e=>setForm({...form,phone:e.target.value})} /></div>
        <button className="btn btn-primary">{editing ? 'Update' : 'Create'}</button>
      </form>
    </div>)}
    <div className="card"><table><thead><tr><th>Name</th><th>Email</th><th>Phone</th><th></th></tr></thead><tbody>
      {clients.map((c:any)=>(<tr key={c.id}><td>{c.name}</td><td>{c.email}</td><td>{c.phone||'-'}</td><td>
        <button className="btn btn-secondary" style={{marginRight:4}} onClick={()=>{setEditing(c.id);setShowForm(true);setForm({name:c.name,email:c.email||'',phone:c.phone||''});}}>Edit</button>
        <button className="btn btn-danger" onClick={()=>handleDelete(c.id)}>Delete</button>
      </td></tr>))}
    </tbody></table></div>
  </div>);
}
