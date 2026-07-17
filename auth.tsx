import React, { createContext, useContext, useState, useCallback } from 'react';
import type { AuthUser, UserRole, LoginCredentials } from './types';
import { getDoctors } from './store';
import { MOCK_ADMIN_CREDENTIALS, MOCK_DOCTOR_CREDENTIALS } from './mockData';

interface AuthContextValue {
  user: AuthUser | null;
  login: (creds: LoginCredentials) => { success: boolean; error?: string };
  logout: () => void;
  isAdmin: boolean;
  isDoctor: boolean;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(() => {
    const raw = localStorage.getItem('tcm_auth_user');
    return raw ? JSON.parse(raw) : null;
  });

  const login = useCallback((creds: LoginCredentials): { success: boolean; error?: string } => {
    const { username, password } = creds;

    // Admin login
    if (username === MOCK_ADMIN_CREDENTIALS.username && password === MOCK_ADMIN_CREDENTIALS.password) {
      const adminUser: AuthUser = {
        id: 'admin',
        name: '系统管理员',
        role: 'admin' as UserRole,
        phone: '',
        avatarPlaceholder: '管',
      };
      localStorage.setItem('tcm_auth_user', JSON.stringify(adminUser));
      setUser(adminUser);
      return { success: true };
    }

    // Doctor login — username is phone or employeeId
    const doctors = getDoctors();
    const doctor = doctors.find(
      (d) =>
        (d.phone === username || d.employeeId === username) &&
        d.status === 'active'
    );

    if (!doctor) {
      return { success: false, error: '账号不存在或已禁用' };
    }

    const expectedPwd = MOCK_DOCTOR_CREDENTIALS[doctor.id] ?? 'doctor123';
    if (password !== expectedPwd) {
      return { success: false, error: '密码错误' };
    }

    const doctorUser: AuthUser = {
      id: doctor.id,
      name: doctor.name,
      role: 'doctor' as UserRole,
      phone: doctor.phone,
      employeeId: doctor.employeeId,
      avatarPlaceholder: doctor.avatarPlaceholder,
    };
    localStorage.setItem('tcm_auth_user', JSON.stringify(doctorUser));
    setUser(doctorUser);
    return { success: true };
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem('tcm_auth_user');
    setUser(null);
  }, []);

  return (
    <AuthContext.Provider
      value={{
        user,
        login,
        logout,
        isAdmin: user?.role === 'admin',
        isDoctor: user?.role === 'doctor',
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
