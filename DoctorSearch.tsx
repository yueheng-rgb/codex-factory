import React, { useState } from 'react';
import { useAuth } from '../auth';
import {
  getPatients, savePatients, addRecord,
  generateId, addLog, addAnomaly, getRecords,
} from '../store';
import type { Patient, TherapyType, VerificationRecord } from '../types';
import ConfirmModal from '../components/ConfirmModal';

const DoctorSearch: React.FC = () => {
  const { user } = useAuth();
  const [search, setSearch] = useState('');
  const [selectedPatient, setSelectedPatient] = useState<Patient | null>(null);
  const [therapyType, setTherapyType] = useState<TherapyType>('火龙罐');
  const [note, setNote] = useState('');
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error' | ''; text: string }>({ type: '', text: '' });

  const patients = getPatients();
  const searchResults = search.trim()
    ? patients.filter((p) => p.name.includes(search) || p.phone.includes(search))
    : [];

  const handleSelect = (patient: Patient) => {
    setSelectedPatient(patient);
    setTherapyType(patient.therapyType);
    setNote('');
    setMessage({ type: '', text: '' });
  };

  const handleVerify = () => {
    if (!selectedPatient || !user) return;

    if (selectedPatient.remainingSessions <= 0) {
      setMessage({ type: 'error', text: '该患者剩余次数不足，无法核销' });
      return;
    }

    setConfirmOpen(true);
  };

  const confirmVerify = () => {
    if (!selectedPatient || !user) return;

    const now = new Date().toISOString();
    const remainingAfter = selectedPatient.remainingSessions - 1;

    // Create record
    const record: VerificationRecord = {
      id: generateId('r'),
      patientId: selectedPatient.id,
      patientName: selectedPatient.name,
      doctorId: user.id,
      doctorName: user.name,
      therapyType,
      note,
      verifiedAt: now,
      remainingAfter,
    };
    addRecord(record);

    // Update patient
    savePatients(patients.map((p) =>
      p.id === selectedPatient.id
        ? { ...p, remainingSessions: remainingAfter, lastVerificationTime: now }
        : p
    ));

    // Anomaly detection (front-end mock)
    detectAnomalies(selectedPatient.id, user.id, record.id, now);

    // Log
    addLog({
      id: generateId('log'), operatorId: user.id, operatorName: user.name,
      role: 'doctor', action: '核销', target: `患者-${selectedPatient.name}`,
      detail: `核销${therapyType}，剩余${remainingAfter}次`,
      timestamp: now,
    });

    setConfirmOpen(false);
    setMessage({ type: 'success', text: `核销成功！${selectedPatient.name} 剩余 ${remainingAfter} 次` });

    // Refresh patient data
    const updatedPatients = getPatients();
    const refreshed = updatedPatients.find((p) => p.id === selectedPatient.id);
    if (refreshed) setSelectedPatient(refreshed);
  };

  const detectAnomalies = (patientId: string, doctorId: string, recordId: string, now: string) => {
    const records = getRecords();
    const doctorRecords = records.filter((r) => r.doctorId === doctorId);

    // High volume: > 20 per day
    const today = now.slice(0, 10);
    const todayCount = doctorRecords.filter((r) => r.verifiedAt.startsWith(today)).length;
    if (todayCount > 20) {
      const patient = patients.find((p) => p.id === patientId);
      addAnomaly({
        id: generateId('a'), type: 'high_volume',
        patientId, patientName: patient?.name ?? '', doctorId,
        doctorName: user!.name, recordId, detectedAt: now,
        description: `医生${user!.name}今日核销次数明显偏高 (${todayCount}次)`,
      });
    }

    // Short-term repeat: same patient within 10 minutes
    const tenMinAgo = new Date(Date.now() - 10 * 60 * 1000).toISOString();
    const recentSamePatient = records.filter(
      (r) => r.patientId === patientId && r.verifiedAt >= tenMinAgo && r.id !== recordId
    );
    if (recentSamePatient.length > 0) {
      const patient = patients.find((p) => p.id === patientId);
      addAnomaly({
        id: generateId('a'), type: 'short_term_repeat',
        patientId, patientName: patient?.name ?? '', doctorId,
        doctorName: user!.name, recordId, detectedAt: now,
        description: `患者${patient?.name}在10分钟内重复核销`,
      });
    }

    // Off-hours: before 8am or after 9pm
    const hour = new Date(now).getHours();
    if (hour < 8 || hour >= 21) {
      const patient = patients.find((p) => p.id === patientId);
      addAnomaly({
        id: generateId('a'), type: 'off_hours',
        patientId, patientName: patient?.name ?? '', doctorId,
        doctorName: user!.name, recordId, detectedAt: now,
        description: `非工作时间核销 (${hour}:00)`,
      });
    }

    // Rapid consecutive: more than 5 in last 5 minutes
    const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
    const rapidCount = doctorRecords.filter((r) => r.verifiedAt >= fiveMinAgo).length;
    if (rapidCount > 5) {
      const patient = patients.find((p) => p.id === patientId);
      addAnomaly({
        id: generateId('a'), type: 'rapid_consecutive',
        patientId, patientName: patient?.name ?? '', doctorId,
        doctorName: user!.name, recordId, detectedAt: now,
        description: `医生${user!.name}在5分钟内连续快速核销 ${rapidCount} 次`,
      });
    }
  };

  return (
    <div>
      <h2 style={{ marginBottom: 20 }}>核销操作</h2>

      {message.text && (
        <div style={{
          padding: '12px 16px', borderRadius: 6, marginBottom: 16,
          background: message.type === 'success' ? '#e8f5e9' : '#ffebee',
          color: message.type === 'success' ? '#2e7d32' : '#c62828',
          fontSize: 14,
        }}>
          {message.text}
        </div>
      )}

      {/* Search */}
      <div style={{ background: '#fff', borderRadius: 8, padding: 20, marginBottom: 20, boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}>
        <h3 style={{ marginBottom: 12 }}>搜索患者</h3>
        <input
          placeholder="输入患者姓名或手机号..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          autoFocus
          style={{
            width: '100%', maxWidth: 400, padding: '10px 14px',
            border: '1px solid #ddd', borderRadius: 6, fontSize: 15,
          }}
        />

        {search.trim() && (
          <div style={{ marginTop: 12 }}>
            {searchResults.length === 0 ? (
              <div style={{ color: '#999', padding: 12 }}>未找到匹配患者</div>
            ) : (
              <table>
                <thead>
                  <tr>
                    <th>姓名</th><th>手机号</th><th>项目</th><th>剩余次数</th><th>操作</th>
                  </tr>
                </thead>
                <tbody>
                  {searchResults.map((p) => (
                    <tr key={p.id} style={{
                      background: selectedPatient?.id === p.id ? '#e3f2fd' : 'transparent',
                    }}>
                      <td>{p.name}</td>
                      <td>{p.phone}</td>
                      <td>{p.therapyType}</td>
                      <td style={{
                        color: p.remainingSessions === 0 ? '#e94560' : '#2e7d32',
                        fontWeight: 600,
                      }}>
                        {p.remainingSessions}
                      </td>
                      <td>
                        <button onClick={() => handleSelect(p)}
                          style={{
                            padding: '4px 12px', background: '#0f3460', color: '#fff',
                            border: 'none', borderRadius: 4, cursor: 'pointer', fontSize: 13,
                          }}>
                          选择
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        )}
      </div>

      {/* Verification form */}
      {selectedPatient && (
        <div style={{ background: '#fff', borderRadius: 8, padding: 20, boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}>
          <h3 style={{ marginBottom: 16 }}>核销确认</h3>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px 24px', marginBottom: 16 }}>
            <div>
              <div style={{ color: '#888', fontSize: 13, marginBottom: 2 }}>患者姓名</div>
              <div style={{ fontWeight: 600, fontSize: 15 }}>{selectedPatient.name}</div>
            </div>
            <div>
              <div style={{ color: '#888', fontSize: 13, marginBottom: 2 }}>剩余次数</div>
              <div style={{
                fontWeight: 700, fontSize: 18,
                color: selectedPatient.remainingSessions === 0 ? '#e94560' : '#2e7d32',
              }}>
                {selectedPatient.remainingSessions}
              </div>
            </div>
            <div>
              <div style={{ color: '#888', fontSize: 13, marginBottom: 2 }}>手机号</div>
              <div style={{ fontWeight: 500 }}>{selectedPatient.phone}</div>
            </div>
            <div>
              <div style={{ color: '#888', fontSize: 13, marginBottom: 2 }}>办卡状态</div>
              <div>{selectedPatient.hasCard ? '已办卡' : '未办卡'}</div>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px 24px', marginBottom: 16 }}>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontWeight: 500 }}>核销项目</label>
              <select value={therapyType} onChange={(e) => setTherapyType(e.target.value as TherapyType)}
                style={{ width: '100%', padding: '8px 10px', border: '1px solid #ddd', borderRadius: 4 }}>
                <option value="火龙罐">火龙罐</option>
                <option value="中药敷药">中药敷药</option>
              </select>
            </div>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontWeight: 500 }}>备注</label>
              <input value={note} onChange={(e) => setNote(e.target.value)}
                placeholder="可选备注..."
                style={{ width: '100%', padding: '8px 10px', border: '1px solid #ddd', borderRadius: 4 }} />
            </div>
          </div>

          <button
            onClick={handleVerify}
            disabled={selectedPatient.remainingSessions <= 0}
            style={{
              padding: '10px 32px', fontSize: 15, border: 'none', borderRadius: 6, cursor: 'pointer',
              background: selectedPatient.remainingSessions <= 0 ? '#ccc' : '#0f3460', color: '#fff',
            }}
          >
            {selectedPatient.remainingSessions <= 0 ? '次数不足，无法核销' : '确认核销'}
          </button>
        </div>
      )}

      <ConfirmModal
        open={confirmOpen}
        title="确认核销"
        message={`确认对患者「${selectedPatient?.name}」进行「${therapyType}」核销吗？\n\n核销后剩余次数将从 ${selectedPatient?.remainingSessions} 变为 ${(selectedPatient?.remainingSessions ?? 0) - 1}。\n\n此操作不可撤销，错误修正需管理员处理。`}
        onConfirm={confirmVerify}
        onCancel={() => setConfirmOpen(false)}
        confirmText="确认核销"
      />
    </div>
  );
};

export default DoctorSearch;
