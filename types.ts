// ============================================================
// TCM Therapy Registration & Verification System — Type Definitions
// ============================================================

export type UserRole = 'admin' | 'doctor';

export type DoctorStatus = 'active' | 'disabled';

export type TherapyType = '火龙罐' | '中药敷药';

export type AnomalyType =
  | 'short_term_repeat'
  | 'off_hours'
  | 'high_volume'
  | 'rapid_consecutive';

export interface Doctor {
  id: string;
  name: string;
  phone: string;
  employeeId: string;       // 工号或身份证后四位
  avatarPlaceholder: string; // 头像占位 (姓名首字)
  status: DoctorStatus;
  createdAt: string;         // ISO datetime
  note: string;
}

export interface Patient {
  id: string;
  name: string;
  phone: string;
  hasCard: boolean;          // 是否办卡
  remainingSessions: number; // 剩余次数
  therapyType: TherapyType;  // 项目类型
  note: string;
  lastVerificationTime: string | null; // 最近核销时间
}

export interface VerificationRecord {
  id: string;
  patientId: string;
  patientName: string;
  doctorId: string;
  doctorName: string;
  therapyType: TherapyType;
  note: string;
  verifiedAt: string;       // ISO datetime
  remainingAfter: number;   // 核销后剩余次数
}

export interface AnomalyRecord {
  id: string;
  type: AnomalyType;
  patientId: string;
  patientName: string;
  doctorId: string;
  doctorName: string;
  recordId: string;         // 关联的核销记录ID
  detectedAt: string;       // ISO datetime
  description: string;
}

export interface OperationLog {
  id: string;
  operatorId: string;
  operatorName: string;
  role: UserRole;
  action: string;
  target: string;
  detail: string;
  timestamp: string;
}

export interface LoginCredentials {
  username: string;
  password: string;
}

export interface AuthUser {
  id: string;
  name: string;
  role: UserRole;
  phone: string;
  employeeId?: string;
  avatarPlaceholder: string;
}
