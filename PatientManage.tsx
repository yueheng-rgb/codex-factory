import React, { useState } from 'react';
import { getPatients, savePatients, generateId, addLog } from '../store';
import type { Patient, TherapyType } from '../types';
import { useAuth } from '../auth';

const PatientManage: React.FC = () => {
  const { user } = useAuth();
  const [patients, setPatients] = useState<Patient[]>(getPatients());
  const [search, setSearch] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);

  const emptyForm: Omit<Patient, 'id'> = {
    name: '', phone: '', hasCard: false, remainingSessions: 0,
    therapyType: '火龙罐', note: '', lastVerificationTime: null,
  };
  const [form, setForm] = useState(emptyForm);

  const refresh = () => setPatients(getPatients());

  const filtered = patients.filter((p) =>
    !search || p.name.includes(search) || p.phone.includes(search)
  );

  const handleSave = () => {
    if (!form.name.trim() || !form.phone.trim()) return;

    if (editingId) {
      const updated = patients.map((p) => p.id === editingId ? { ...p, ...form } : p);
      savePatients(updated);
      addLog({
        id: generateId('log'), operatorId: user!.id, operatorName: user!.name,
        role: 'admin', action: '编辑患者', target: `患者-${form.name}`, detail: '编辑患者信息',
        timestamp: new Date().toISOString(),
      });
    } else {
      const newPatient: Patient = { id: generateId('p'), ...form };
      savePatients([...patients, newPatient]);
      addLog({
        id: generateId('log'), operatorId: user!.id, operatorName: user!.name,
        role: 'admin', action: '新增患者', target: `患者-${form.name}`, detail: `创建患者: ${form.name}, 项目: ${form.therapyType}`,
        timestamp: new Date().toISOString(),
      });
    }
    refresh();
    setShowForm(false);
    setEditingId(null);
    setForm(emptyForm);
  };

  const startEdit = (patient: Patient) => {
    setForm({
      name: patient.name, phone: patient.phone, hasCard: patient.hasCard,
      remainingSessions: patient.remainingSessions, therapyType: patient.therapyType,
      note: patient.note, lastVerificationTime: patient.lastVerificationTime,
    });
    setEditingId(patient.id);
    setShowForm(true);
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <h2>患者/会员信息管理</h2>
        <button onClick={() => { setForm(emptyForm); setEditingId(null); setShowForm(!showForm); }}
          style={{ padding: '8px 20px', background: '#0f3460', color: '#fff', border: 'none', borderRadius: 4, cursor: 'pointer' }}>
          {showForm ? '取消' : '新增患者'}
        </button>
      </div>

      <div style={{ marginBottom: 16 }}>
        <input
          placeholder="搜索患者姓名或手机号..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{ width: '100%', maxWidth: 400, padding: '10px 12px', border: '1px solid #ddd', borderRadius: 6, fontSize: 14 }}
        />
      </div>

      {showForm && (
        <div style={{ background: '#fff', borderRadius: 8, padding: 20, marginBottom: 20, boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}>
          <h3 style={{ marginBottom: 16 }}>{editingId ? '编辑患者' : '新增患者'}</h3>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px 20px' }}>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontWeight: 500 }}>姓名 *</label>
              <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })}
                style={{ width: '100%', padding: '8px 10px', border: '1px solid #ddd', borderRadius: 4 }} />
            </div>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontWeight: 500 }}>手机号 *</label>
              <input value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })}
                style={{ width: '100%', padding: '8px 10px', border: '1px solid #ddd', borderRadius: 4 }} />
            </div>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontWeight: 500 }}>是否办卡</label>
              <select value={form.hasCard ? 'yes' : 'no'} onChange={(e) => setForm({ ...form, hasCard: e.target.value === 'yes' })}
                style={{ width: '100%', padding: '8px 10px', border: '1px solid #ddd', borderRadius: 4 }}>
                <option value="no">否</option>
                <option value="yes">是</option>
              </select>
            </div>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontWeight: 500 }}>项目类型</label>
              <select value={form.therapyType} onChange={(e) => setForm({ ...form, therapyType: e.target.value as TherapyType })}
                style={{ width: '100%', padding: '8px 10px', border: '1px solid #ddd', borderRadius: 4 }}>
                <option value="火龙罐">火龙罐</option>
                <option value="中药敷药">中药敷药</option>
              </select>
            </div>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontWeight: 500 }}>剩余次数</label>
              <input type="number" min={0} value={form.remainingSessions}
                onChange={(e) => setForm({ ...form, remainingSessions: Math.max(0, parseInt(e.target.value) || 0) })}
                style={{ width: '100%', padding: '8px 10px', border: '1px solid #ddd', borderRadius: 4 }} />
            </div>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontWeight: 500 }}>备注</label>
              <input value={form.note} onChange={(e) => setForm({ ...form, note: e.target.value })}
                style={{ width: '100%', padding: '8px 10px', border: '1px solid #ddd', borderRadius: 4 }} />
            </div>
          </div>
          <button onClick={handleSave}
            style={{ marginTop: 16, padding: '8px 24px', background: '#0f3460', color: '#fff', border: 'none', borderRadius: 4, cursor: 'pointer' }}>
            保存
          </button>
        </div>
      )}

      <div style={{ background: '#fff', borderRadius: 8, boxShadow: '0 2px 8px rgba(0,0,0,0.08)', overflow: 'auto' }}>
        <table>
          <thead>
            <tr>
              <th>姓名</th><th>手机号</th><th>办卡</th><th>剩余次数</th><th>项目类型</th><th>最近核销</th><th>备注</th><th>操作</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr><td colSpan={8} style={{ textAlign: 'center', color: '#999', padding: 24 }}>暂无数据</td></tr>
            ) : filtered.map((p) => (
              <tr key={p.id}>
                <td>{p.name}</td>
                <td>{p.phone}</td>
                <td>{p.hasCard ? '是' : '否'}</td>
                <td style={{ color: p.remainingSessions === 0 ? '#e94560' : '#333', fontWeight: 600 }}>
                  {p.remainingSessions}
                </td>
                <td>{p.therapyType}</td>
                <td>{p.lastVerificationTime ? new Date(p.lastVerificationTime).toLocaleString('zh-CN') : '-'}</td>
                <td style={{ maxWidth: 120, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.note || '-'}</td>
                <td>
                  <button onClick={() => startEdit(p)}
                    style={{ cursor: 'pointer', background: 'none', border: 'none', color: '#0f3460', fontSize: 13 }}>
                    编辑
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default PatientManage;
