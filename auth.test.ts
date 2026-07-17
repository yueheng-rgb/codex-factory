import { describe, it, expect, beforeEach } from 'vitest';

// We test the auth logic indirectly through the store/mock data layer
// since AuthProvider requires React context.

import { getDoctors } from '../src/store';
import { MOCK_ADMIN_CREDENTIALS, MOCK_DOCTOR_CREDENTIALS } from '../src/mockData';

describe('Auth Logic (store-level)', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('admin credentials exist and are testable', () => {
    expect(MOCK_ADMIN_CREDENTIALS.username).toBe('admin');
    expect(MOCK_ADMIN_CREDENTIALS.password).toBeTruthy();
  });

  it('doctor credentials map has entries for active doctors', () => {
    const doctors = getDoctors();
    const activeDoctors = doctors.filter((d) => d.status === 'active');
    activeDoctors.forEach((d) => {
      expect(MOCK_DOCTOR_CREDENTIALS[d.id]).toBeTruthy();
    });
  });

  it('disabled doctors still have credentials (but login blocks them)', () => {
    const doctors = getDoctors();
    const disabledDoctor = doctors.find((d) => d.status === 'disabled');
    if (disabledDoctor) {
      // Credential exists but status check in auth.tsx blocks login
      expect(MOCK_DOCTOR_CREDENTIALS[disabledDoctor.id]).toBeTruthy();
    }
  });

  it('doctor can be looked up by phone', () => {
    const doctors = getDoctors();
    const doctor = doctors.find((d) => d.phone === '13800001111');
    expect(doctor).toBeTruthy();
    expect(doctor?.name).toBe('张明');
  });

  it('doctor can be looked up by employeeId', () => {
    const doctors = getDoctors();
    const doctor = doctors.find((d) => d.employeeId === 'ZM001');
    expect(doctor).toBeTruthy();
    expect(doctor?.name).toBe('张明');
  });

  it('non-existent user lookup returns undefined', () => {
    const doctors = getDoctors();
    const doctor = doctors.find((d) => d.phone === '00000000000');
    expect(doctor).toBeUndefined();
  });
});
