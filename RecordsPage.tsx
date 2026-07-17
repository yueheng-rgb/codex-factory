import React, { useState } from 'react';
import { getRecords } from '../store';
import type { TherapyType } from '../types';

const RecordsPage: React.FC = () => {
  const [search, setSearch] = useState('');
  const [filterDoctor, setFilterDoctor] = useState('');
  const [filterType, setFilterType] = useState<TherapyType | ''>('');

  const records = getRecords();
  const doctors = [...new Set(records.map((r) => r.doctorName))];

  const filtered = records
    .filter((r) => !search || r.patientName.includes(search) || r.patientId.includes(search))
    .filter((r) => !filterDoctor || r.doctorName === filterDoctor)
    .filter((r) => !filterType || r.therapyType === filterType)
    .sort((a, b) => b.verifiedAt.localeCompare(a.verifiedAt));

  return (
    <div>
      <h2 style={{ marginBottom: 20 }}>核销记录查看</h2>

      <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
        <input
          placeholder="搜索患者姓名..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{ padding: '8px 12px', border: '1px solid #ddd', borderRadius: 4, width: 200 }}
        />
        <select value={filterDoctor} onChange={(e) => setFilterDoctor(e.target.value)}
          style={{ padding: '8px 12px', border: '1px solid #ddd', borderRadius: 4 }}>
          <option value="">全部医生</option>
          {doctors.map((d) => <option key={d} value={d}>{d}</option>)}
        </select>
        <select value={filterType} onChange={(e) => setFilterType(e.target.value as TherapyType | '')}
          style={{ padding: '8px 12px', border: '1px solid #ddd', borderRadius: 4 }}>
          <option value="">全部项目</option>
          <option value="火龙罐">火龙罐</option>
          <option value="中药敷药">中药敷药</option>
        </select>
        <span style={{ alignSelf: 'center', color: '#888', fontSize: 13 }}>
          共 {filtered.length} 条记录
        </span>
      </div>

      <div style={{ background: '#fff', borderRadius: 8, boxShadow: '0 2px 8px rgba(0,0,0,0.08)', overflow: 'auto' }}>
        <table>
          <thead>
            <tr>
              <th>患者</th><th>医生</th><th>项目</th><th>备注</th><th>核销时间</th><th>剩余次数</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr><td colSpan={6} style={{ textAlign: 'center', color: '#999', padding: 24 }}>暂无核销记录</td></tr>
            ) : filtered.map((r) => (
              <tr key={r.id}>
                <td>{r.patientName}</td>
                <td>{r.doctorName}</td>
                <td><span style={{
                  padding: '2px 8px', borderRadius: 10, fontSize: 12,
                  background: r.therapyType === '火龙罐' ? '#fff3e0' : '#e8f5e9',
                  color: r.therapyType === '火龙罐' ? '#e65100' : '#2e7d32',
                }}>{r.therapyType}</span></td>
                <td style={{ maxWidth: 150, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{r.note || '-'}</td>
                <td>{new Date(r.verifiedAt).toLocaleString('zh-CN')}</td>
                <td style={{ color: r.remainingAfter === 0 ? '#e94560' : '#333', fontWeight: 600 }}>{r.remainingAfter}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default RecordsPage;
