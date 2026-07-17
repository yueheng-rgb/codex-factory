import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth';

const LoginPage: React.FC = () => {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!username.trim()) { setError('请输入账号'); return; }
    if (!password.trim()) { setError('请输入密码'); return; }

    setLoading(true);
    // Simulate slight delay for UX
    setTimeout(() => {
      const result = login({ username: username.trim(), password });
      setLoading(false);
      if (result.success) {
        const stored = localStorage.getItem('tcm_auth_user');
        if (stored) {
          const u = JSON.parse(stored);
          navigate(u.role === 'admin' ? '/admin' : '/doctor');
        }
      } else {
        setError(result.error ?? '登录失败');
      }
    }, 300);
  };

  return (
    <div style={{
      minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'linear-gradient(135deg, #0f3460, #16213e)',
    }}>
      <div style={{
        background: '#fff', borderRadius: 12, padding: '40px 36px', width: 380,
        boxShadow: '0 8px 32px rgba(0,0,0,0.2)',
      }}>
        <h1 style={{ textAlign: 'center', margin: '0 0 4px', fontSize: 22 }}>中医理疗登记与核销系统</h1>
        <p style={{ textAlign: 'center', color: '#888', margin: '0 0 28px', fontSize: 13 }}>
          账号由管理员统一录入和发放
        </p>
        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: 16 }}>
            <label style={{ display: 'block', marginBottom: 6, fontWeight: 500, fontSize: 14 }}>
              账号
            </label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="管理员: admin / 医生: 手机号或工号"
              style={{
                width: '100%', padding: '10px 12px', border: '1px solid #ddd', borderRadius: 6,
                fontSize: 14, boxSizing: 'border-box',
              }}
              autoFocus
            />
          </div>
          <div style={{ marginBottom: 24 }}>
            <label style={{ display: 'block', marginBottom: 6, fontWeight: 500, fontSize: 14 }}>
              密码
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="输入密码"
              style={{
                width: '100%', padding: '10px 12px', border: '1px solid #ddd', borderRadius: 6,
                fontSize: 14, boxSizing: 'border-box',
              }}
            />
          </div>
          {error && (
            <div style={{
              color: '#e94560', fontSize: 13, marginBottom: 16,
              padding: '8px 12px', background: '#fff0f0', borderRadius: 4,
            }}>
              {error}
            </div>
          )}
          <button
            type="submit"
            disabled={loading}
            style={{
              width: '100%', padding: '12px', background: loading ? '#999' : '#0f3460',
              color: '#fff', border: 'none', borderRadius: 6, fontSize: 16, cursor: loading ? 'not-allowed' : 'pointer',
            }}
          >
            {loading ? '登录中...' : '登 录'}
          </button>
        </form>
        <div style={{ marginTop: 20, fontSize: 12, color: '#aaa', textAlign: 'center' }}>
          测试账号: admin / admin123 | 医生: 13800001111 / doctor123
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
