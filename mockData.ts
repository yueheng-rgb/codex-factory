import type { Doctor, Patient, VerificationRecord, AnomalyRecord, OperationLog } from './types';

export const MOCK_DOCTORS: Doctor[] = [
  {
    id: 'd001',
    name: '张明',
    phone: '13800001111',
    employeeId: 'ZM001',
    avatarPlaceholder: '张',
    status: 'active',
    createdAt: '2025-01-15T09:00:00.000Z',
    note: '资深中医师',
  },
  {
    id: 'd002',
    name: '李芳',
    phone: '13800002222',
    employeeId: 'LF002',
    avatarPlaceholder: '李',
    status: 'active',
    createdAt: '2025-03-01T09:00:00.000Z',
    note: '',
  },
  {
    id: 'd003',
    name: '王伟',
    phone: '13800003333',
    employeeId: 'WW003',
    avatarPlaceholder: '王',
    status: 'disabled',
    createdAt: '2025-06-10T09:00:00.000Z',
    note: '已离职',
  },
];

export const MOCK_PATIENTS: Patient[] = [
  {
    id: 'p001',
    name: '赵国强',
    phone: '13900001111',
    hasCard: true,
    remainingSessions: 5,
    therapyType: '火龙罐',
    note: '腰椎问题',
    lastVerificationTime: '2026-06-19T10:30:00.000Z',
  },
  {
    id: 'p002',
    name: '孙丽华',
    phone: '13900002222',
    hasCard: true,
    remainingSessions: 8,
    therapyType: '中药敷药',
    note: '',
    lastVerificationTime: '2026-06-18T14:00:00.000Z',
  },
  {
    id: 'p003',
    name: '周建国',
    phone: '13900003333',
    hasCard: false,
    remainingSessions: 1,
    therapyType: '火龙罐',
    note: '肩颈问题',
    lastVerificationTime: '2026-06-19T09:00:00.000Z',
  },
  {
    id: 'p004',
    name: '吴秀英',
    phone: '13900004444',
    hasCard: true,
    remainingSessions: 12,
    therapyType: '中药敷药',
    note: '慢性疼痛',
    lastVerificationTime: null,
  },
  {
    id: 'p005',
    name: '陈志强',
    phone: '13900005555',
    hasCard: true,
    remainingSessions: 0,
    therapyType: '火龙罐',
    note: '已用完',
    lastVerificationTime: '2026-06-17T16:00:00.000Z',
  },
];

export const MOCK_RECORDS: VerificationRecord[] = [
  {
    id: 'r001',
    patientId: 'p001',
    patientName: '赵国强',
    doctorId: 'd001',
    doctorName: '张明',
    therapyType: '火龙罐',
    note: '第三次理疗',
    verifiedAt: '2026-06-19T10:30:00.000Z',
    remainingAfter: 5,
  },
  {
    id: 'r002',
    patientId: 'p002',
    patientName: '孙丽华',
    doctorId: 'd002',
    doctorName: '李芳',
    therapyType: '中药敷药',
    note: '',
    verifiedAt: '2026-06-18T14:00:00.000Z',
    remainingAfter: 8,
  },
  {
    id: 'r003',
    patientId: 'p003',
    patientName: '周建国',
    doctorId: 'd001',
    doctorName: '张明',
    therapyType: '火龙罐',
    note: '首次',
    verifiedAt: '2026-06-19T09:00:00.000Z',
    remainingAfter: 1,
  },
  {
    id: 'r004',
    patientId: 'p005',
    patientName: '陈志强',
    doctorId: 'd001',
    doctorName: '张明',
    therapyType: '火龙罐',
    note: '末次核销',
    verifiedAt: '2026-06-17T16:00:00.000Z',
    remainingAfter: 0,
  },
];

export const MOCK_ANOMALIES: AnomalyRecord[] = [
  {
    id: 'a001',
    type: 'high_volume',
    patientId: 'p001',
    patientName: '赵国强',
    doctorId: 'd001',
    doctorName: '张明',
    recordId: 'r001',
    detectedAt: '2026-06-19T10:30:01.000Z',
    description: '医生张明今日核销次数明显偏高',
  },
];

export const MOCK_LOGS: OperationLog[] = [
  {
    id: 'l001',
    operatorId: 'admin',
    operatorName: '管理员',
    role: 'admin',
    action: '新增医生',
    target: '医生-王伟',
    detail: '创建医生账号: 王伟 (WW003)',
    timestamp: '2025-06-10T09:00:00.000Z',
  },
];

export const MOCK_ADMIN_CREDENTIALS = {
  username: 'admin',
  password: 'admin123',
};

export const MOCK_DOCTOR_CREDENTIALS: Record<string, string> = {
  d001: 'doctor123',
  d002: 'doctor123',
  d003: 'doctor123',
};
