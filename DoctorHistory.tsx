import React, { useMemo, useState } from 'react';
import { useAuth } from '../auth';
import { getRecords } from '../store';

const DoctorHistory: React.FC = () => {
  const { user } = useAuth();
  const [search, setSearch] = useState('');

  const records = getRecords();
  const myRecords = useMemo(
    () =>
      records
        .filter((r) => r.doctorId === user!.id && (!search || r.patientName.includes(search)))
        .sort((a, b) => b.verifiedAt.localeCompare(a.verifiedAt)),
    [records, user, search]
  );

  return (
    <div>
      <h2 style={{ marginBottom: 20 }}>个人历史记录</h2>

      <div style={{ marginBottom: 16 }}>
        <input
          placeholder="搜索患者姓名..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{ padding: '10px 12px', border: '1px solid #ddd', borderRadius: 6, width: 300, fontSize: 14 }}
        />
        <span style={{ marginLeft: 12, color: '#888', fontSize: 13 }}>
          共 {myRecords.length} 条记录
        </span>
      </div>

      <div style={{ background: '#fff', borderRadius: 8, boxShadow: '0 2px 8px rgba(0,0,0,0.08)', overflow: 'auto' }}>
        <table>
          <thead>
            <tr>
              <th>患者</th><th>项目</th><th>备注</th><th>核销时间</th><th>剩余次数</th>
            </tr>
          </thead>
          <tbody>
            {myRecords.length === 0 ? (
              <tr><td colSpan={5} style={{ textAlign: 'center', color: '#999', padding: 24 }}>
                暂无历史记录
              </td></tr>
            ) : myRecords.map((r) => (
              <tr key={r.id}>
                <td>{r.patientName}</td>
                <td><span style={{
                  padding: '2px 8px', borderRadius: 10, fontSize: 12,
                  background: r.therapyType === '火龙罐' ? '#fff3e0' : '#e8f5e9',
                  color: r.therapyType === '火龙罐' ? '#e65100' : '#2e7d32',
                }}>{r.therapyType}</span></td>
                <td style={{ maxWidth: 150, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{r.note || '-'}</td>
                <td>{new Date(r.verifiedAt).toLocaleString('zh-CN')}</td>
                <td style={{ fontWeight: 600, color: r.remainingAfter === 0 ? '#e94560' : '#333' }}>
                  {r.remainingAfter}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default DoctorHistory;
