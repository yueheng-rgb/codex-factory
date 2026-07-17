import React, { useMemo } from 'react';
import { getRecords, getAnomalies } from '../store';

const StatsPage: React.FC = () => {
  const records = getRecords();
  const anomalies = getAnomalies();

  // Stats by doctor
  const byDoctor = useMemo(() => {
    const map: Record<string, number> = {};
    records.forEach((r) => { map[r.doctorName] = (map[r.doctorName] || 0) + 1; });
    return Object.entries(map).sort((a, b) => b[1] - a[1]);
  }, [records]);

  // Stats by therapy type
  const byType = useMemo(() => {
    const map: Record<string, number> = {};
    records.forEach((r) => { map[r.therapyType] = (map[r.therapyType] || 0) + 1; });
    return Object.entries(map).sort((a, b) => b[1] - a[1]);
  }, [records]);

  // Stats by date (last 7 days)
  const byDate = useMemo(() => {
    const map: Record<string, number> = {};
    const today = new Date();
    for (let i = 6; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(d.getDate() - i);
      map[d.toISOString().slice(0, 10)] = 0;
    }
    records.forEach((r) => {
      const day = r.verifiedAt.slice(0, 10);
      if (map[day] !== undefined) map[day]++;
    });
    return Object.entries(map);
  }, [records]);

  const maxDateCount = Math.max(1, ...byDate.map(([, c]) => c));

  return (
    <div>
      <h2 style={{ marginBottom: 20 }}>统计报表</h2>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
        {/* By Doctor */}
        <div style={{ background: '#fff', borderRadius: 8, padding: 20, boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}>
          <h3 style={{ marginBottom: 16 }}>按医生统计核销次数</h3>
          {byDoctor.length === 0 ? (
            <div style={{ color: '#999', textAlign: 'center', padding: 20 }}>暂无数据</div>
          ) : (
            <table>
              <thead><tr><th>医生</th><th style={{ textAlign: 'right' }}>核销次数</th></tr></thead>
              <tbody>
                {byDoctor.map(([name, count]) => (
                  <tr key={name}>
                    <td>{name}</td>
                    <td style={{ textAlign: 'right', fontWeight: 600 }}>{count}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {/* By Type */}
        <div style={{ background: '#fff', borderRadius: 8, padding: 20, boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}>
          <h3 style={{ marginBottom: 16 }}>按项目统计核销次数</h3>
          {byType.length === 0 ? (
            <div style={{ color: '#999', textAlign: 'center', padding: 20 }}>暂无数据</div>
          ) : (
            <table>
              <thead><tr><th>项目</th><th style={{ textAlign: 'right' }}>核销次数</th></tr></thead>
              <tbody>
                {byType.map(([name, count]) => (
                  <tr key={name}>
                    <td>{name}</td>
                    <td style={{ textAlign: 'right', fontWeight: 600 }}>{count}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* By Date Chart */}
      <div style={{ background: '#fff', borderRadius: 8, padding: 20, marginTop: 20, boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}>
        <h3 style={{ marginBottom: 16 }}>按日期统计核销次数 (近7天)</h3>
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 16, height: 200, padding: '0 20px' }}>
          {byDate.map(([date, count]) => (
            <div key={date} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <div style={{ fontSize: 12, marginBottom: 4, fontWeight: 500 }}>{count}</div>
              <div style={{
                width: '100%', maxWidth: 60,
                height: Math.max(4, (count / maxDateCount) * 140),
                background: 'linear-gradient(to top, #0f3460, #e94560)',
                borderRadius: '4px 4px 0 0',
                transition: 'height 0.3s',
              }} />
              <div style={{ fontSize: 11, color: '#888', marginTop: 6 }}>
                {date.slice(5)}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Anomaly summary */}
      <div style={{ background: '#fff', borderRadius: 8, padding: 20, marginTop: 20, boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}>
        <h3 style={{ marginBottom: 8 }}>异常记录数量</h3>
        <div style={{ fontSize: 32, fontWeight: 700, color: anomalies.length > 0 ? '#e94560' : '#2ecc71' }}>
          {anomalies.length}
        </div>
      </div>
    </div>
  );
};

export default StatsPage;
