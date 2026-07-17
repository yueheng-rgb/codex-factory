import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './auth';
import Layout from './components/Layout';
import LoginPage from './pages/LoginPage';
import AdminDashboard from './pages/AdminDashboard';
import DoctorManage from './pages/DoctorManage';
import PatientManage from './pages/PatientManage';
import RecordsPage from './pages/RecordsPage';
import StatsPage from './pages/StatsPage';
import AnomaliesPage from './pages/AnomaliesPage';
import DoctorSearch from './pages/DoctorSearch';
import DoctorToday from './pages/DoctorToday';
import DoctorHistory from './pages/DoctorHistory';

const ProtectedRoute: React.FC<{ role: 'admin' | 'doctor'; children: React.ReactNode }> = ({
  role, children,
}) => {
  const { user } = useAuth();
  if (!user) return <Navigate to="/login" replace />;
  if (user.role !== role) return <Navigate to={user.role === 'admin' ? '/admin' : '/doctor'} replace />;
  return <Layout>{children}</Layout>;
};

const App: React.FC = () => {
  const { user } = useAuth();

  return (
    <Routes>
      <Route path="/login" element={user ? <Navigate to={user.role === 'admin' ? '/admin' : '/doctor'} replace /> : <LoginPage />} />

      {/* Admin routes */}
      <Route path="/admin" element={<ProtectedRoute role="admin"><AdminDashboard /></ProtectedRoute>} />
      <Route path="/admin/doctors" element={<ProtectedRoute role="admin"><DoctorManage /></ProtectedRoute>} />
      <Route path="/admin/patients" element={<ProtectedRoute role="admin"><PatientManage /></ProtectedRoute>} />
      <Route path="/admin/records" element={<ProtectedRoute role="admin"><RecordsPage /></ProtectedRoute>} />
      <Route path="/admin/stats" element={<ProtectedRoute role="admin"><StatsPage /></ProtectedRoute>} />
      <Route path="/admin/anomalies" element={<ProtectedRoute role="admin"><AnomaliesPage /></ProtectedRoute>} />

      {/* Doctor routes */}
      <Route path="/doctor" element={<ProtectedRoute role="doctor"><DoctorSearch /></ProtectedRoute>} />
      <Route path="/doctor/today" element={<ProtectedRoute role="doctor"><DoctorToday /></ProtectedRoute>} />
      <Route path="/doctor/history" element={<ProtectedRoute role="doctor"><DoctorHistory /></ProtectedRoute>} />

      {/* Default redirect */}
      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
};

export default App;
