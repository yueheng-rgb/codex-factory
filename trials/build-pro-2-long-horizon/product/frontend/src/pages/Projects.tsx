import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { projectApi } from '../services/api';

export default function Projects() {
  const [projects, setProjects] = useState<any[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: '', description: '' });
  const nav = useNavigate();
  useEffect(() => { projectApi.list().then(r => setProjects(r.data || [])).catch(()=>{}); }, []);
  const handleSubmit = async (e: React.FormEvent) => { e.preventDefault();
    try { await projectApi.create(form); setShowForm(false); setForm({ name: '', description: '' });
      const r = await projectApi.list(); setProjects(r.data || []); } catch (err: any) { alert(err.message); } };
  return (<div>
    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
      <h2>Projects</h2>
      <button className="btn btn-primary" onClick={()=>setShowForm(!showForm)}>{showForm?'Cancel':'+ New Project'}</button>
    </div>
    {showForm && (<div className="card">
      <form onSubmit={handleSubmit}>
        <div className="form-group"><label>Name</label><input value={form.name} onChange={e=>setForm({...form,name:e.target.value})} required /></div>
        <div className="form-group"><label>Description</label><textarea value={form.description} onChange={e=>setForm({...form,description:e.target.value})} /></div>
        <button className="btn btn-primary">Create</button>
      </form>
    </div>)}
    <div className="card"><table><thead><tr><th>Name</th><th>Status</th><th></th></tr></thead><tbody>
      {projects.map((p:any)=>(<tr key={p.id}><td>{p.name}</td><td><span className="badge badge-new">{p.status}</span></td><td>
        <button className="btn btn-secondary" onClick={()=>nav(`/projects/${p.id}/tasks`)}>Tasks</button>
      </td></tr>))}
    </tbody></table></div>
  </div>);
}
