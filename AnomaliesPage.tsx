import React, { useState } from 'react';
import { getAnomalies } from '../store';
import type { AnomalyType } from '../types';

const TYPE_LABELS: Record<AnomalyType, string> = {
  short_term_repeat: '短时重复核销',
  off_hours: '非工作时间核销',
  high_volume: '单医核销次数偏高',
  rapid_consecutive: '连续快速核销',
};

const TYPE_COLORS: Record<AnomalyType, string> = {
  short_term_repeat: '#ff9800',
  off_hours: '#9c27b0',
  high_volume: '#f44336',
  rapid_consecutive: '#ff5722',
};

const AnomaliesPage: React.FC = () => {
  const [filterType, setFilterType] = useState<AnomalyType | ''>('');

  const anomalies = getAnomalies();
  const filtered = filterType
    ? anomalies.filter((a) => a.type === filterType)
    : anomalies;

  return (
    <div>
      <h2 style={{ marginBottom: 20 }}>异常记录</h2>

      <div style={{ marginBottom: 16 }}>
        <select value={filterType} onChange={(e) => setFilterType(e.target.value as AnomalyType | '')}
          style={{ padding: '8px 12px', border: '1px solid #ddd', borderRadius: 4 }}>
          <option value="">全部类型</option>
          {(Object.keys(TYPE_LABELS) as AnomalyType[]).map((t) => (
            <option key={t} value={t}>{TYPE_LABELS[t]}</option>
          ))}
        </select>
        <span style={{ marginLeft: 12, color: '#888', fontSize: 13 }}>共 {filtered.length} 条</span>
      </div>

      <div style={{ background: '#fff', borderRadius: 8, boxShadow: '0 2px 8px rgba(0,0,0,0.08)', overflow: 'auto' }}>
        <table>
          <thead>
            <tr>
              <th>类型</th><th>患者</th><th>医生</th><th>检测时间</th><th>说明</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr><td colSpan={5} style={{ textAlign: 'center', color: '#999', padding: 24 }}>
                {anomalies.length === 0 ? '暂无异常记录，一切正常 ✅' : '无匹配的异常记录'}
              </td></tr>
            ) : filtered.map((a) => (
              <tr key={a.id}>
                <td>
                  <span style={{
                    padding: '2px 8px', borderRadius: 10, fontSize: 12,
                    background: TYPE_COLORS[a.type] + '20',
                    color: TYPE_COLORS[a.type], fontWeight: 500,
                  }}>
                    {TYPE_LABELS[a.type]}
                  </span>
                </td>
                <td>{a.patientName}</td>
                <td>{a.doctorName}</td>
                <td>{new Date(a.detectedAt).toLocaleString('zh-CN')}</td>
                <td style={{ maxWidth: 300 }}>{a.description}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default AnomaliesPage;
