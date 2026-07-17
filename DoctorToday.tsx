import React, { useMemo } from 'react';
import { useAuth } from '../auth';
import { getRecords } from '../store';

const DoctorToday: React.FC = () => {
  const { user } = useAuth();
  const records = getRecords();
  const today = new Date().toISOString().slice(0, 10);

  const todayRecords = useMemo(
    () =>
      records
        .filter((r) => r.doctorId === user!.id && r.verifiedAt.startsWith(today))
        .sort((a, b) => b.verifiedAt.localeCompare(a.verifiedAt)),
    [records, user, today]
  );

  const typeCounts = useMemo(() => {
    const map: Record<string, number> = {};
    todayRecords.forEach((r) => { map[r.therapyType] = (map[r.therapyType] || 0) + 1; });
    return map;
  }, [todayRecords]);

  return (
    <div>
      <h2 style={{ marginBottom: 20 }}>今日统计 — {today}</h2>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16, marginBottom: 24 }}>
        <div style={{ background: '#fff', borderRadius: 8, padding: 20, boxShadow: '0 2px 8px rgba(0,0,0,0.08)', textAlign: 'center' }}>
          <div style={{ fontSize: 13, color: '#888', marginBottom: 8 }}>今日核销总数</div>
          <div style={{ fontSize: 32, fontWeight: 700, color: '#0f3460' }}>{todayRecords.length}</div>
        </div>
        <div style={{ background: '#fff', borderRadius: 8, padding: 20, boxShadow: '0 2px 8px rgba(0,0,0,0.08)', textAlign: 'center' }}>
          <div style={{ fontSize: 13, color: '#888', marginBottom: 8 }}>火龙罐</div>
          <div style={{ fontSize: 32, fontWeight: 700, color: '#e65100' }}>{typeCounts['火龙罐'] || 0}</div>
        </div>
        <div style={{ background: '#fff', borderRadius: 8, padding: 20, boxShadow: '0 2px 8px rgba(0,0,0,0.08)', textAlign: 'center' }}>
          <div style={{ fontSize: 13, color: '#888', marginBottom: 8 }}>中药敷药</div>
          <div style={{ fontSize: 32, fontWeight: 700, color: '#2e7d32' }}>{typeCounts['中药敷药'] || 0}</div>
        </div>
      </div>

      <div style={{ background: '#fff', borderRadius: 8, padding: 20, boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}>
        <h3 style={{ marginBottom: 12 }}>今日核销明细</h3>
        {todayRecords.length === 0 ? (
          <div style={{ color: '#999', textAlign: 'center', padding: 20 }}>今日暂无核销记录</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>患者</th><th>项目</th><th>备注</th><th>时间</th><th>剩余</th>
              </tr>
            </thead>
            <tbody>
              {todayRecords.map((r) => (
                <tr key={r.id}>
                  <td>{r.patientName}</td>
                  <td>{r.therapyType}</td>
                  <td>{r.note || '-'}</td>
                  <td>{new Date(r.verifiedAt).toLocaleTimeString('zh-CN')}</td>
                  <td style={{ fontWeight: 600, color: r.remainingAfter === 0 ? '#e94560' : '#333' }}>
                    {r.remainingAfter}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default DoctorToday;
