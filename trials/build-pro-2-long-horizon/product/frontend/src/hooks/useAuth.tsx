import React, { createContext, useContext, useState, useCallback, useEffect } from 'react';
import { authApi } from '../services/api';

interface AuthState { user: any; token: string; }
interface AuthContextType { auth: AuthState | null; login: (email: string, password: string) => Promise<void>; register: (data: any) => Promise<void>; logout: () => void; }
const AuthContext = createContext<AuthContextType>(null!);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [auth, setAuth] = useState<AuthState | null>(() => {
    const stored = localStorage.getItem('nexusdesk_auth');
    return stored ? JSON.parse(stored) : null;
  });
  useEffect(() => { if (auth) localStorage.setItem('nexusdesk_auth', JSON.stringify(auth)); else localStorage.removeItem('nexusdesk_auth'); }, [auth]);
  const login = useCallback(async (email: string, password: string) => {
    const res = await authApi.login(email, password);
    setAuth({ user: res.data.user, token: res.data.token });
  }, []);
  const register = useCallback(async (data: any) => {
    const res = await authApi.register(data);
    setAuth({ user: res.data.user, token: '' });
  }, []);
  const logout = useCallback(() => setAuth(null), []);
  return <AuthContext.Provider value={{ auth, login, register, logout }}>{children}</AuthContext.Provider>;
}
export function useAuth() { return useContext(AuthContext); }
