// ============================================================
// localStorage-based State Management
// ============================================================

import type {
  Doctor, Patient, VerificationRecord, AnomalyRecord, OperationLog,
} from './types';
import {
  MOCK_DOCTORS, MOCK_PATIENTS, MOCK_RECORDS, MOCK_ANOMALIES, MOCK_LOGS,
} from './mockData';

const KEYS = {
  doctors: 'tcm_doctors',
  patients: 'tcm_patients',
  records: 'tcm_records',
  anomalies: 'tcm_anomalies',
  logs: 'tcm_logs',
};

function loadOrInit<T>(key: string, fallback: T[]): T[] {
  const raw = localStorage.getItem(key);
  if (raw) {
    try { return JSON.parse(raw) as T[]; } catch { /* fall through */ }
  }
  localStorage.setItem(key, JSON.stringify(fallback));
  return fallback;
}

function save<T>(key: string, data: T[]): void {
  localStorage.setItem(key, JSON.stringify(data));
}

// ---- Doctors ----
export function getDoctors(): Doctor[] {
  return loadOrInit<Doctor>(KEYS.doctors, MOCK_DOCTORS);
}
export function saveDoctors(doctors: Doctor[]): void {
  save(KEYS.doctors, doctors);
}
export function addDoctor(doctor: Doctor): Doctor[] {
  const list = getDoctors();
  list.push(doctor);
  saveDoctors(list);
  return list;
}
export function updateDoctor(id: string, patch: Partial<Doctor>): Doctor[] {
  const list = getDoctors();
  const idx = list.findIndex((d) => d.id === id);
  if (idx >= 0) list[idx] = { ...list[idx], ...patch };
  saveDoctors(list);
  return list;
}

// ---- Patients ----
export function getPatients(): Patient[] {
  return loadOrInit<Patient>(KEYS.patients, MOCK_PATIENTS);
}
export function savePatients(patients: Patient[]): void {
  save(KEYS.patients, patients);
}
export function addPatient(patient: Patient): Patient[] {
  const list = getPatients();
  list.push(patient);
  savePatients(list);
  return list;
}
export function updatePatient(id: string, patch: Partial<Patient>): Patient[] {
  const list = getPatients();
  const idx = list.findIndex((p) => p.id === id);
  if (idx >= 0) list[idx] = { ...list[idx], ...patch };
  savePatients(list);
  return list;
}

// ---- Records ----
export function getRecords(): VerificationRecord[] {
  return loadOrInit<VerificationRecord>(KEYS.records, MOCK_RECORDS);
}
export function saveRecords(records: VerificationRecord[]): void {
  save(KEYS.records, records);
}
export function addRecord(record: VerificationRecord): VerificationRecord[] {
  const list = getRecords();
  list.push(record);
  saveRecords(list);
  return list;
}

// ---- Anomalies ----
export function getAnomalies(): AnomalyRecord[] {
  return loadOrInit<AnomalyRecord>(KEYS.anomalies, MOCK_ANOMALIES);
}
export function saveAnomalies(anomalies: AnomalyRecord[]): void {
  save(KEYS.anomalies, anomalies);
}
export function addAnomaly(anomaly: AnomalyRecord): AnomalyRecord[] {
  const list = getAnomalies();
  list.push(anomaly);
  saveAnomalies(list);
  return list;
}

// ---- Logs ----
export function getLogs(): OperationLog[] {
  return loadOrInit<OperationLog>(KEYS.logs, MOCK_LOGS);
}
export function saveLogs(logs: OperationLog[]): void {
  save(KEYS.logs, logs);
}
export function addLog(log: OperationLog): OperationLog[] {
  const list = getLogs();
  list.push(log);
  saveLogs(list);
  return list;
}

// ---- Reset (for admin) ----
export function resetAllData(): void {
  localStorage.setItem(KEYS.doctors, JSON.stringify(MOCK_DOCTORS));
  localStorage.setItem(KEYS.patients, JSON.stringify(MOCK_PATIENTS));
  localStorage.setItem(KEYS.records, JSON.stringify(MOCK_RECORDS));
  localStorage.setItem(KEYS.anomalies, JSON.stringify(MOCK_ANOMALIES));
  localStorage.setItem(KEYS.logs, JSON.stringify(MOCK_LOGS));
}

// ---- Utility ----
export function generateId(prefix: string): string {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}
