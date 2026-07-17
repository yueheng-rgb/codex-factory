import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { taskApi } from '../services/api';

export default function Tasks() {
  const { projectId } = useParams();
  const [tasks, setTasks] = useState<any[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ title: '', description: '', priority: 'medium' });
  useEffect(() => { if (projectId) taskApi.listByProject(projectId).then(r => setTasks(r.data || [])).catch(()=>{}); }, [projectId]);
  const handleSubmit = async (e: React.FormEvent) => { e.preventDefault();
    try { await taskApi.create({ ...form, projectId }); setShowForm(false); setForm({ title: '', description: '', priority: 'medium' });
      const r = await taskApi.listByProject(projectId!); setTasks(r.data || []); } catch (err: any) { alert(err.message); } };
  const updateStatus = async (id: string, status: string) => {
    const t = tasks.find(x=>x.id===id); if (!t) return;
    await taskApi.update(id, { ...t, status }); const r = await taskApi.listByProject(projectId!); setTasks(r.data || []); };
  return (<div>
    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
      <h2>Tasks</h2>
      <button className="btn btn-primary" onClick={()=>setShowForm(!showForm)}>{showForm?'Cancel':'+ New Task'}</button>
    </div>
    {showForm && (<div className="card">
      <form onSubmit={handleSubmit}>
        <div className="form-group"><label>Title</label><input value={form.title} onChange={e=>setForm({...form,title:e.target.value})} required /></div>
        <div className="form-group"><label>Description</label><textarea value={form.description} onChange={e=>setForm({...form,description:e.target.value})} /></div>
        <div className="form-group"><label>Priority</label><select value={form.priority} onChange={e=>setForm({...form,priority:e.target.value})}>
          <option value="low">Low</option><option value="medium">Medium</option><option value="high">High</option><option value="urgent">Urgent</option></select></div>
        <button className="btn btn-primary">Create</button>
      </form>
    </div>)}
    <div className="card"><table><thead><tr><th>Title</th><th>Priority</th><th>Status</th><th>Action</th></tr></thead><tbody>
      {tasks.map((t:any)=>(<tr key={t.id}><td>{t.title}</td><td><span className={`badge badge-${t.priority}`}>{t.priority}</span></td>
        <td><span className={`badge badge-${t.status==='done'?'done':'new'}`}>{t.status}</span></td><td>
        {t.status!=='done'&&<button className="btn btn-secondary" style={{marginRight:4}} onClick={()=>updateStatus(t.id,'in_progress')}>Start</button>}
        {t.status==='in_progress'&&<button className="btn btn-primary" onClick={()=>updateStatus(t.id,'done')}>Done</button>}
      </td></tr>))}
    </tbody></table></div>
  </div>);
}
