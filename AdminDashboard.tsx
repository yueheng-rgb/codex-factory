import React from 'react';
import { useAuth } from '../auth';
import { getDoctors, getPatients, getRecords, getAnomalies } from '../store';

const AdminDashboard: React.FC = () => {
  const { user } = useAuth();
  const doctors = getDoctors();
  const patients = getPatients();
  const records = getRecords();
  const anomalies = getAnomalies();

  const activeDoctors = doctors.filter((d) => d.status === 'active').length;
  const today = new Date().toISOString().slice(0, 10);
  const todayRecords = records.filter((r) => r.verifiedAt.startsWith(today)).length;
  const pendingAnomalies = anomalies.length;

  const cards = [
    { label: '活跃医生', value: activeDoctors, color: '#0f3460' },
    { label: '患者总数', value: patients.length, color: '#16213e' },
    { label: '今日核销', value: todayRecords, color: '#e94560' },
    { label: '异常记录', value: pendingAnomalies, color: pendingAnomalies > 0 ? '#ff6b6b' : '#2ecc71' },
  ];

  // Recent records
  const recentRecords = [...records].sort((a, b) => b.verifiedAt.localeCompare(a.verifiedAt)).slice(0, 5);

  return (
    <div>
      <h2 style={{ marginBottom: 20 }}>管理员首页 — 欢迎, {user?.name}</h2>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 24 }}>
        {cards.map((c) => (
          <div key={c.label} style={{
            background: '#fff', borderRadius: 8, padding: 20,
            boxShadow: '0 2px 8px rgba(0,0,0,0.08)', textAlign: 'center',
          }}>
            <div style={{ fontSize: 13, color: '#888', marginBottom: 8 }}>{c.label}</div>
            <div style={{ fontSize: 28, fontWeight: 700, color: c.color }}>{c.value}</div>
          </div>
        ))}
      </div>

      <div style={{ background: '#fff', borderRadius: 8, padding: 20, boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}>
        <h3 style={{ marginBottom: 12 }}>最近核销记录</h3>
        {recentRecords.length === 0 ? (
          <div style={{ color: '#999', padding: '20px 0', textAlign: 'center' }}>暂无核销记录</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>患者</th><th>医生</th><th>项目</th><th>时间</th><th>剩余次数</th>
              </tr>
            </thead>
            <tbody>
              {recentRecords.map((r) => (
                <tr key={r.id}>
                  <td>{r.patientName}</td>
                  <td>{r.doctorName}</td>
                  <td>{r.therapyType}</td>
                  <td>{new Date(r.verifiedAt).toLocaleString('zh-CN')}</td>
                  <td style={{ color: r.remainingAfter === 0 ? '#e94560' : '#333' }}>{r.remainingAfter}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default AdminDashboard;
