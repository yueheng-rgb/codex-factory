import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';

const TICKET_STATUSES = ['new','triaged','assigned','waiting_customer','resolved','closed'];
const API = '/api';
async function api(path: string, opts: any = {}) {
  const auth = JSON.parse(localStorage.getItem('nexusdesk_auth')||'{}');
  const h: any = {'Content-Type':'application/json'}; if(auth.token) h['Authorization']=`Bearer ${auth.token}`;
  const r = await fetch(`${API}${path}`,{...opts,headers:h});
  if(!r.ok){const e=await r.json().catch(()=>({error:'Failed'}));throw new Error(e.error);}
  return r.json();
}

export default function Tickets() {
  const { projectId } = useParams();
  const [tickets, setTickets] = useState<any[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ title:'', description:'', priority:'medium' });
  useEffect(()=>{if(projectId)api(`/tickets/project/${projectId}`).then(r=>setTickets(r.data||[])).catch(()=>{});},[projectId]);
  const handleSubmit = async (e: React.FormEvent) => { e.preventDefault();
    try{await api('/tickets',{method:'POST',body:JSON.stringify({...form,projectId})});setShowForm(false);setForm({title:'',description:'',priority:'medium'});
    const r=await api(`/tickets/project/${projectId}`);setTickets(r.data||[]);}catch(err:any){alert(err.message);} };
  const updateStatus = async (id: string, status: string) => {
    try{await api(`/tickets/${id}`,{method:'PUT',body:JSON.stringify({status})});
    const r=await api(`/tickets/project/${projectId}`);setTickets(r.data||[]);}catch(err:any){alert(err.message);} };
  return (<div>
    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
      <h2>Tickets</h2><button className="btn btn-primary" onClick={()=>setShowForm(!showForm)}>{showForm?'Cancel':'+ New Ticket'}</button>
    </div>
    {showForm&&(<div className="card"><form onSubmit={handleSubmit}>
      <div className="form-group"><label>Title</label><input value={form.title} onChange={e=>setForm({...form,title:e.target.value})} required /></div>
      <div className="form-group"><label>Description</label><textarea value={form.description} onChange={e=>setForm({...form,description:e.target.value})} /></div>
      <div className="form-group"><label>Priority</label><select value={form.priority} onChange={e=>setForm({...form,priority:e.target.value})}>
        <option value="low">Low</option><option value="medium">Medium</option><option value="high">High</option><option value="urgent">Urgent</option></select></div>
      <button className="btn btn-primary">Create</button></form></div>)}
    <div className="card"><table><thead><tr><th>Title</th><th>Priority</th><th>Status</th><th>Action</th></tr></thead><tbody>
      {tickets.map((t:any)=>(<tr key={t.id}><td>{t.title}</td><td><span className={`badge badge-${t.priority}`}>{t.priority}</span></td>
        <td><span className={`badge badge-${t.status==='closed'?'done':'new'}`}>{t.status}</span></td><td>
        {t.status==='new'&&<button className="btn btn-secondary" style={{marginRight:4}} onClick={()=>updateStatus(t.id,'triaged')}>Triage</button>}
        {t.status==='triaged'&&<button className="btn btn-secondary" style={{marginRight:4}} onClick={()=>updateStatus(t.id,'assigned')}>Assign</button>}
        {t.status==='assigned'&&<button className="btn btn-secondary" style={{marginRight:4}} onClick={()=>updateStatus(t.id,'waiting_customer')}>Wait Customer</button>}
        {t.status==='waiting_customer'&&<button className="btn btn-primary" style={{marginRight:4}} onClick={()=>updateStatus(t.id,'resolved')}>Resolve</button>}
        {t.status==='resolved'&&<button className="btn btn-primary" style={{marginRight:4}} onClick={()=>updateStatus(t.id,'closed')}>Close</button>}
        {(t.status!=='closed')&&<button className="btn btn-danger" onClick={()=>updateStatus(t.id,'closed')}>Close</button>}
      </td></tr>))}
    </tbody></table></div>
  </div>);
}
