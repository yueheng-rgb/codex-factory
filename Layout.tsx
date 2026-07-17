import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../auth';

const Layout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user, logout, isAdmin } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const adminNav = [
    { path: '/admin', label: '首页' },
    { path: '/admin/doctors', label: '医生管理' },
    { path: '/admin/patients', label: '患者管理' },
    { path: '/admin/records', label: '核销记录' },
    { path: '/admin/stats', label: '统计报表' },
    { path: '/admin/anomalies', label: '异常记录' },
  ];

  const doctorNav = [
    { path: '/doctor', label: '核销操作' },
    { path: '/doctor/today', label: '今日统计' },
    { path: '/doctor/history', label: '历史记录' },
  ];

  const navItems = isAdmin ? adminNav : doctorNav;

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      {/* Sidebar */}
      <aside style={{
        width: 200,
        background: '#1a1a2e',
        color: '#eee',
        padding: '20px 0',
        flexShrink: 0,
      }}>
        <div style={{ padding: '0 16px 20px', borderBottom: '1px solid #333' }}>
          <div style={{ fontWeight: 700, fontSize: 16 }}>中医理疗系统</div>
          <div style={{ fontSize: 12, color: '#999', marginTop: 4 }}>
            {user?.role === 'admin' ? '管理员端' : '医生端'}
          </div>
        </div>
        <div style={{ padding: '12px 16px', borderBottom: '1px solid #333', marginBottom: 8 }}>
          <div style={{ fontWeight: 600, fontSize: 14 }}>{user?.name}</div>
          <div style={{ fontSize: 12, color: '#888' }}>
            {user?.role === 'admin' ? '系统管理员' : user?.employeeId ?? user?.phone}
          </div>
        </div>
        <nav>
          {navItems.map((item) => (
            <div
              key={item.path}
              onClick={() => navigate(item.path)}
              style={{
                padding: '10px 20px',
                cursor: 'pointer',
                background: location.pathname === item.path ? '#16213e' : 'transparent',
                borderLeft: location.pathname === item.path ? '3px solid #e94560' : '3px solid transparent',
                transition: 'all 0.2s',
              }}
            >
              {item.label}
            </div>
          ))}
        </nav>
        <div style={{ marginTop: 'auto', padding: '20px 16px' }}>
          <button
            onClick={logout}
            style={{
              width: '100%', padding: '8px', background: '#e94560', color: '#fff',
              border: 'none', borderRadius: 4, cursor: 'pointer',
            }}
          >
            退出登录
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main style={{ flex: 1, padding: 24, background: '#f5f5f5', overflow: 'auto' }}>
        {children}
      </main>
    </div>
  );
};

export default Layout;
