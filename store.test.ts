import { describe, it, expect, beforeEach } from 'vitest';
import {
  getDoctors, addDoctor, updateDoctor,
  getPatients, addPatient, updatePatient,
  getRecords, addRecord,
  getAnomalies, addAnomaly,
  getLogs, addLog,
  resetAllData, generateId,
} from '../src/store';
import type { Doctor, Patient, VerificationRecord, AnomalyRecord, OperationLog } from '../src/types';

beforeEach(() => {
  localStorage.clear();
  resetAllData();
});

describe('Doctor CRUD', () => {
  it('loads mock doctors on first access', () => {
    const doctors = getDoctors();
    expect(doctors.length).toBeGreaterThanOrEqual(3);
    expect(doctors[0]).toHaveProperty('name');
    expect(doctors[0]).toHaveProperty('phone');
    expect(doctors[0]).toHaveProperty('status');
  });

  it('adds a new doctor', () => {
    const newDoc: Doctor = {
      id: 'd-test',
      name: '测试医生',
      phone: '13900009999',
      employeeId: 'TEST01',
      avatarPlaceholder: '测',
      status: 'active',
      createdAt: new Date().toISOString(),
      note: '',
    };
    const list = addDoctor(newDoc);
    expect(list.find((d) => d.id === 'd-test')).toBeTruthy();

    const reloaded = getDoctors();
    expect(reloaded.find((d) => d.id === 'd-test')).toBeTruthy();
  });

  it('updates a doctor', () => {
    updateDoctor('d001', { name: '张明(已更新)', note: '更新备注' });
    const reloaded = getDoctors();
    const updated = reloaded.find((d) => d.id === 'd001');
    expect(updated?.name).toBe('张明(已更新)');
    expect(updated?.note).toBe('更新备注');
  });

  it('persists doctors to localStorage', () => {
    const doctors = getDoctors();
    const raw = localStorage.getItem('tcm_doctors');
    expect(raw).toBeTruthy();
    const parsed = JSON.parse(raw!);
    expect(parsed.length).toBe(doctors.length);
  });
});

describe('Patient CRUD', () => {
  it('loads mock patients', () => {
    const patients = getPatients();
    expect(patients.length).toBeGreaterThanOrEqual(5);
  });

  it('adds a new patient', () => {
    const newPatient: Patient = {
      id: 'p-test',
      name: '测试患者',
      phone: '13900008888',
      hasCard: true,
      remainingSessions: 10,
      therapyType: '火龙罐',
      note: '',
      lastVerificationTime: null,
    };
    const list = addPatient(newPatient);
    expect(list.find((p) => p.id === 'p-test')).toBeTruthy();
  });

  it('updates patient remaining sessions', () => {
    updatePatient('p001', { remainingSessions: 3 });
    const reloaded = getPatients();
    const updated = reloaded.find((p) => p.id === 'p001');
    expect(updated?.remainingSessions).toBe(3);
  });

  it('persists patients to localStorage', () => {
    getPatients();
    const raw = localStorage.getItem('tcm_patients');
    expect(raw).toBeTruthy();
  });
});

describe('Record CRUD', () => {
  it('loads mock records', () => {
    const records = getRecords();
    expect(records.length).toBeGreaterThanOrEqual(4);
  });

  it('adds a verification record', () => {
    const record: VerificationRecord = {
      id: 'r-test',
      patientId: 'p001',
      patientName: '赵国强',
      doctorId: 'd001',
      doctorName: '张明',
      therapyType: '火龙罐',
      note: '测试核销',
      verifiedAt: new Date().toISOString(),
      remainingAfter: 4,
    };
    const list = addRecord(record);
    expect(list.find((r) => r.id === 'r-test')).toBeTruthy();
  });

  it('persists records to localStorage', () => {
    getRecords();
    const raw = localStorage.getItem('tcm_records');
    expect(raw).toBeTruthy();
  });
});

describe('Anomaly CRUD', () => {
  it('loads mock anomalies', () => {
    const anomalies = getAnomalies();
    expect(anomalies.length).toBeGreaterThanOrEqual(0);
  });

  it('adds an anomaly record', () => {
    const anomaly: AnomalyRecord = {
      id: 'a-test',
      type: 'high_volume',
      patientId: 'p001',
      patientName: '赵国强',
      doctorId: 'd001',
      doctorName: '张明',
      recordId: 'r001',
      detectedAt: new Date().toISOString(),
      description: '测试异常',
    };
    const list = addAnomaly(anomaly);
    expect(list.find((a) => a.id === 'a-test')).toBeTruthy();
  });
});

describe('Log CRUD', () => {
  it('loads mock logs', () => {
    const logs = getLogs();
    expect(logs.length).toBeGreaterThanOrEqual(0);
  });

  it('adds an operation log', () => {
    const log: OperationLog = {
      id: 'l-test',
      operatorId: 'd001',
      operatorName: '张明',
      role: 'doctor',
      action: '核销',
      target: '患者-赵国强',
      detail: '核销测试',
      timestamp: new Date().toISOString(),
    };
    const list = addLog(log);
    expect(list.find((l) => l.id === 'l-test')).toBeTruthy();
  });
});

describe('resetAllData', () => {
  it('resets all data to mock defaults', () => {
    addDoctor({
      id: 'd-extra', name: '额外医生', phone: '13800005555',
      employeeId: 'EX001', avatarPlaceholder: '额', status: 'active',
      createdAt: new Date().toISOString(), note: '',
    });
    expect(getDoctors().length).toBeGreaterThan(3);

    resetAllData();
    expect(getDoctors().length).toBe(3);
  });
});

describe('generateId', () => {
  it('generates unique IDs with prefix', () => {
    const id1 = generateId('d');
    const id2 = generateId('d');
    expect(id1.startsWith('d-')).toBe(true);
    expect(id1).not.toBe(id2);
  });
});
