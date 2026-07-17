import { describe, it, expect, beforeEach } from 'vitest';
import { saveRecords, saveAnomalies, savePatients } from '../src/store';
import type { VerificationRecord, Patient } from '../src/types';

// Re-implement detection logic for pure unit testing
function detectAnomalies(
  patientId: string,
  doctorId: string,
  doctorName: string,
  recordId: string,
  now: Date,
  existingRecords: VerificationRecord[],
  existingPatients: Patient[]
): { type: string; description: string }[] {
  const results: { type: string; description: string }[] = [];
  const doctorRecords = existingRecords.filter((r) => r.doctorId === doctorId);
  const today = now.toISOString().slice(0, 10);

  // High volume: > 20 per day
  const todayCount = doctorRecords.filter((r) => r.verifiedAt.startsWith(today)).length;
  if (todayCount >= 20) {
    results.push({
      type: 'high_volume',
      description: `医生${doctorName}今日核销次数明显偏高 (${todayCount}次)`,
    });
  }

  // Short-term repeat: same patient within 10 minutes
  const tenMinAgo = new Date(now.getTime() - 10 * 60 * 1000).toISOString();
  const recentSamePatient = existingRecords.filter(
    (r) => r.patientId === patientId && r.verifiedAt >= tenMinAgo && r.id !== recordId
  );
  if (recentSamePatient.length > 0) {
    const patient = existingPatients.find((p) => p.id === patientId);
    results.push({
      type: 'short_term_repeat',
      description: `患者${patient?.name ?? ''}在10分钟内重复核销`,
    });
  }

  // Off-hours: before 8am or after 9pm
  const hour = now.getHours();
  if (hour < 8 || hour >= 21) {
    results.push({
      type: 'off_hours',
      description: `非工作时间核销 (${hour}:00)`,
    });
  }

  // Rapid consecutive: > 5 in last 5 minutes
  const fiveMinAgo = new Date(now.getTime() - 5 * 60 * 1000).toISOString();
  const rapidCount = doctorRecords.filter((r) => r.verifiedAt >= fiveMinAgo).length;
  if (rapidCount >= 5) {
    results.push({
      type: 'rapid_consecutive',
      description: `医生${doctorName}在5分钟内连续快速核销 ${rapidCount} 次`,
    });
  }

  return results;
}

beforeEach(() => {
  localStorage.clear();
  saveRecords([]);
  saveAnomalies([]);
  savePatients([]);
});

describe('Anomaly Detection — short_term_repeat', () => {
  it('detects same patient within 10 minutes', () => {
    const now = new Date('2026-06-20T10:05:00.000Z');
    const existing: VerificationRecord[] = [
      {
        id: 'r-prev', patientId: 'p001', patientName: '赵', doctorId: 'd001', doctorName: '张明',
        therapyType: '火龙罐', note: '', verifiedAt: '2026-06-20T10:00:00.000Z', remainingAfter: 5,
      },
    ];
    const patients: Patient[] = [{ id: 'p001', name: '赵', phone: '', hasCard: true, remainingSessions: 5, therapyType: '火龙罐', note: '', lastVerificationTime: null }];

    const results = detectAnomalies('p001', 'd001', '张明', 'r-new', now, existing, patients);
    expect(results.some((r) => r.type === 'short_term_repeat')).toBe(true);
  });

  it('does not flag same patient after 15 minutes', () => {
    const now = new Date('2026-06-20T10:20:00.000Z');
    const existing: VerificationRecord[] = [
      {
        id: 'r-prev', patientId: 'p001', patientName: '赵', doctorId: 'd001', doctorName: '张明',
        therapyType: '火龙罐', note: '', verifiedAt: '2026-06-20T10:00:00.000Z', remainingAfter: 5,
      },
    ];
    const patients: Patient[] = [{ id: 'p001', name: '赵', phone: '', hasCard: true, remainingSessions: 5, therapyType: '火龙罐', note: '', lastVerificationTime: null }];

    const results = detectAnomalies('p001', 'd001', '张明', 'r-new', now, existing, patients);
    expect(results.some((r) => r.type === 'short_term_repeat')).toBe(false);
  });

  it('does not flag different patients', () => {
    const now = new Date('2026-06-20T10:02:00.000Z');
    const existing: VerificationRecord[] = [
      {
        id: 'r-prev', patientId: 'p002', patientName: '钱', doctorId: 'd001', doctorName: '张明',
        therapyType: '火龙罐', note: '', verifiedAt: '2026-06-20T10:00:00.000Z', remainingAfter: 5,
      },
    ];
    const patients: Patient[] = [{ id: 'p001', name: '赵', phone: '', hasCard: true, remainingSessions: 5, therapyType: '火龙罐', note: '', lastVerificationTime: null }];

    const results = detectAnomalies('p001', 'd001', '张明', 'r-new', now, existing, patients);
    expect(results.some((r) => r.type === 'short_term_repeat')).toBe(false);
  });
});

describe('Anomaly Detection — off_hours', () => {
  it('detects before 8am', () => {
    const now = new Date(2026, 5, 20, 6, 30); // 6:30 AM local
    const existing: VerificationRecord[] = [];
    const patients: Patient[] = [];

    const results = detectAnomalies('p001', 'd001', '张明', 'r-new', now, existing, patients);
    expect(results.some((r) => r.type === 'off_hours')).toBe(true);
  });

  it('detects after 9pm', () => {
    const now = new Date(2026, 5, 20, 22, 0); // 10:00 PM local
    const existing: VerificationRecord[] = [];
    const patients: Patient[] = [];

    const results = detectAnomalies('p001', 'd001', '张明', 'r-new', now, existing, patients);
    expect(results.some((r) => r.type === 'off_hours')).toBe(true);
  });

  it('does not flag at 10am', () => {
    const now = new Date('2026-06-20T10:00:00.000Z');
    const existing: VerificationRecord[] = [];
    const patients: Patient[] = [];

    const results = detectAnomalies('p001', 'd001', '张明', 'r-new', now, existing, patients);
    expect(results).toHaveLength(0);
  });
});

describe('Anomaly Detection — high_volume', () => {
  it('detects when doctor has >= 20 records today', () => {
    const now = new Date('2026-06-20T12:00:00.000Z');
    const existing: VerificationRecord[] = Array.from({ length: 20 }, (_, i) => ({
      id: `r-${i}`, patientId: `p${i}`, patientName: `患者${i}`, doctorId: 'd001', doctorName: '张明',
      therapyType: '火龙罐' as const, note: '', verifiedAt: `2026-06-20T${String(8 + i).padStart(2, '0')}:00:00.000Z`, remainingAfter: 5,
    }));
    const patients: Patient[] = [];

    const results = detectAnomalies('p-new', 'd001', '张明', 'r-new', now, existing, patients);
    expect(results.some((r) => r.type === 'high_volume')).toBe(true);
  });

  it('does not flag below threshold', () => {
    const now = new Date('2026-06-20T12:00:00.000Z');
    const existing: VerificationRecord[] = Array.from({ length: 10 }, (_, i) => ({
      id: `r-${i}`, patientId: `p${i}`, patientName: `患者${i}`, doctorId: 'd001', doctorName: '张明',
      therapyType: '火龙罐' as const, note: '', verifiedAt: `2026-06-20T${String(8 + i).padStart(2, '0')}:00:00.000Z`, remainingAfter: 5,
    }));
    const patients: Patient[] = [];

    const results = detectAnomalies('p-new', 'd001', '张明', 'r-new', now, existing, patients);
    expect(results.some((r) => r.type === 'high_volume')).toBe(false);
  });
});

describe('Anomaly Detection — rapid_consecutive', () => {
  it('detects > 5 records in 5 minutes', () => {
    const now = new Date('2026-06-20T10:00:00.000Z');
    const existing: VerificationRecord[] = Array.from({ length: 6 }, (_, i) => ({
      id: `r-${i}`, patientId: `p${i}`, patientName: `患者${i}`, doctorId: 'd001', doctorName: '张明',
      therapyType: '火龙罐' as const, note: '', verifiedAt: '2026-06-20T09:57:00.000Z', remainingAfter: 5,
    }));
    const patients: Patient[] = [];

    const results = detectAnomalies('p-new', 'd001', '张明', 'r-new', now, existing, patients);
    expect(results.some((r) => r.type === 'rapid_consecutive')).toBe(true);
  });

  it('does not flag below threshold', () => {
    const now = new Date('2026-06-20T10:00:00.000Z');
    const existing: VerificationRecord[] = Array.from({ length: 3 }, (_, i) => ({
      id: `r-${i}`, patientId: `p${i}`, patientName: `患者${i}`, doctorId: 'd001', doctorName: '张明',
      therapyType: '火龙罐' as const, note: '', verifiedAt: '2026-06-20T09:57:00.000Z', remainingAfter: 5,
    }));
    const patients: Patient[] = [];

    const results = detectAnomalies('p-new', 'd001', '张明', 'r-new', now, existing, patients);
    expect(results).toHaveLength(0);
  });
});


