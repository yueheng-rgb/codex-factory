import React, { useState } from 'react';
import { getDoctors, saveDoctors, generateId, addLog } from '../store';
import type { Doctor, DoctorStatus } from '../types';
import { useAuth } from '../auth';
import ConfirmModal from '../components/ConfirmModal';

const DoctorManage: React.FC = () => {
  const { user } = useAuth();
  const [doctors, setDoctors] = useState<Doctor[]>(getDoctors());
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [confirmDisable, setConfirmDisable] = useState<{ open: boolean; doctor: Doctor | null }>({ open: false, doctor: null });

  const emptyForm: Omit<Doctor, 'id' | 'createdAt'> = {
    name: '', phone: '', employeeId: '', avatarPlaceholder: '', status: 'active', note: '',
  };
  const [form, setForm] = useState(emptyForm);

  const refresh = () => setDoctors(getDoctors());

  const handleSave = () => {
    if (!form.name.trim() || !form.phone.trim()) return;

    if (editingId) {
      const updated = doctors.map((d) => d.id === editingId ? {
        ...d,
        name: form.name,
        phone: form.phone,
        employeeId: form.employeeId,
        avatarPlaceholder: form.name.charAt(0),
        status: form.status,
        note: form.note,
      } : d);
      saveDoctors(updated);
      addLog({
        id: generateId('log'), operatorId: user!.id, operatorName: user!.name,
        role: 'admin', action: '编辑医生', target: `医生-${form.name}`, detail: `编辑医生信息`,
        timestamp: new Date().toISOString(),
      });
    } else {
      const newDoctor: Doctor = {
        id: generateId('d'),
        ...form,
        avatarPlaceholder: form.name.charAt(0),
        createdAt: new Date().toISOString(),
      };
      const updated = [...doctors, newDoctor];
      saveDoctors(updated);
      addLog({
        id: generateId('log'), operatorId: user!.id, operatorName: user!.name,
        role: 'admin', action: '新增医生', target: `医生-${form.name}`, detail: `创建医生账号: ${form.name}`,
        timestamp: new Date().toISOString(),
      });
    }
    refresh();
    setShowForm(false);
    setEditingId(null);
    setForm(emptyForm);
  };

  const toggleStatus = (doctor: Doctor) => {
    if (doctor.status === 'active') {
      setConfirmDisable({ open: true, doctor });
    } else {
      const updated = doctors.map((d) => d.id === doctor.id ? { ...d, status: 'active' as DoctorStatus } : d);
      saveDoctors(updated);
      refresh();
    }
  };

  const confirmToggleStatus = () => {
    if (!confirmDisable.doctor) return;
    const updated = doctors.map((d) => d.id === confirmDisable.doctor!.id ? { ...d, status: 'disabled' as DoctorStatus } : d);
    saveDoctors(updated);
    addLog({
      id: generateId('log'), operatorId: user!.id, operatorName: user!.name,
      role: 'admin', action: '禁用医生', target: `医生-${confirmDisable.doctor.name}`, detail: '禁用医生账号',
      timestamp: new Date().toISOString(),
    });
    refresh();
    setConfirmDisable({ open: false, doctor: null });
  };

  const startEdit = (doctor: Doctor) => {
    setForm({
      name: doctor.name, phone: doctor.phone, employeeId: doctor.employeeId,
      avatarPlaceholder: doctor.avatarPlaceholder, status: doctor.status, note: doctor.note,
    });
    setEditingId(doctor.id);
    setShowForm(true);
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <h2>医生账号管理</h2>
        <button onClick={() => { setForm(emptyForm); setEditingId(null); setShowForm(!showForm); }}
          style={{ padding: '8px 20px', background: '#0f3460', color: '#fff', border: 'none', borderRadius: 4, cursor: 'pointer' }}>
          {showForm ? '取消' : '新增医生'}
        </button>
      </div>

      {showForm && (
        <div style={{ background: '#fff', borderRadius: 8, padding: 20, marginBottom: 20, boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}>
          <h3 style={{ marginBottom: 16 }}>{editingId ? '编辑医生' : '新增医生'}</h3>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px 20px' }}>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontWeight: 500 }}>医生姓名 *</label>
              <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })}
                style={{ width: '100%', padding: '8px 10px', border: '1px solid #ddd', borderRadius: 4 }} />
            </div>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontWeight: 500 }}>手机号 *</label>
              <input value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })}
                style={{ width: '100%', padding: '8px 10px', border: '1px solid #ddd', borderRadius: 4 }} />
            </div>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontWeight: 500 }}>工号/身份证后四位</label>
              <input value={form.employeeId} onChange={(e) => setForm({ ...form, employeeId: e.target.value })}
                style={{ width: '100%', padding: '8px 10px', border: '1px solid #ddd', borderRadius: 4 }} />
            </div>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontWeight: 500 }}>状态</label>
              <select value={form.status} onChange={(e) => setForm({ ...form, status: e.target.value as DoctorStatus })}
                style={{ width: '100%', padding: '8px 10px', border: '1px solid #ddd', borderRadius: 4 }}>
                <option value="active">正常</option>
                <option value="disabled">禁用</option>
              </select>
            </div>
            <div style={{ gridColumn: '1 / -1' }}>
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

      <div style={{ background: '#fff', borderRadius: 8, boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}>
        <table>
          <thead>
            <tr>
              <th>头像</th><th>姓名</th><th>手机号</th><th>工号/身份证</th><th>状态</th><th>创建时间</th><th>备注</th><th>操作</th>
            </tr>
          </thead>
          <tbody>
            {doctors.map((d) => (
              <tr key={d.id}>
                <td>
                  <div style={{
                    width: 36, height: 36, borderRadius: '50%', background: '#0f3460', color: '#fff',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 600, fontSize: 14,
                  }}>
                    {d.avatarPlaceholder}
                  </div>
                </td>
                <td>{d.name}</td>
                <td>{d.phone}</td>
                <td>{d.employeeId}</td>
                <td>
                  <span style={{
                    padding: '2px 8px', borderRadius: 10, fontSize: 12,
                    background: d.status === 'active' ? '#e8f5e9' : '#ffebee',
                    color: d.status === 'active' ? '#2e7d32' : '#c62828',
                  }}>
                    {d.status === 'active' ? '正常' : '禁用'}
                  </span>
                </td>
                <td>{new Date(d.createdAt).toLocaleDateString('zh-CN')}</td>
                <td style={{ maxWidth: 150, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{d.note || '-'}</td>
                <td>
                  <button onClick={() => startEdit(d)} style={{ marginRight: 8, cursor: 'pointer', background: 'none', border: 'none', color: '#0f3460', fontSize: 13 }}>编辑</button>
                  <button onClick={() => toggleStatus(d)}
                    style={{ cursor: 'pointer', background: 'none', border: 'none', color: d.status === 'active' ? '#e94560' : '#2ecc71', fontSize: 13 }}>
                    {d.status === 'active' ? '禁用' : '启用'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <ConfirmModal
        open={confirmDisable.open}
        title="确认禁用"
        message={`确定要禁用医生「${confirmDisable.doctor?.name}」吗？禁用后该医生将无法登录系统。`}
        onConfirm={confirmToggleStatus}
        onCancel={() => setConfirmDisable({ open: false, doctor: null })}
        confirmText="确认禁用"
        danger
      />
    </div>
  );
};

export default DoctorManage;
