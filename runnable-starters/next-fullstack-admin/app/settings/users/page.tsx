"use client";

import AppShell from "@/components/AppShell";
import EmptyState from "@/components/EmptyState";

export default function UsersSettingsPage() {
  return (
    <AppShell title="用户管理" role="admin">
      <div className="panel">
        <h2 style={{ marginBottom: 16 }}>用户与权限</h2>
        <p style={{ color: "#666", marginBottom: 16 }}>
          此页面为占位页面，展示用户和权限管理的基本结构。
        </p>
        <p style={{ color: "#888", fontSize: 14 }}>
          ⚠️ 真实项目必须实现：
        </p>
        <ul style={{ color: "#888", fontSize: 14, paddingLeft: 20, marginTop: 8 }}>
          <li>用户 CRUD（列表、新增、编辑、禁用）</li>
          <li>角色管理（admin / user / 自定义角色）</li>
          <li>所有权限在服务端校验</li>
          <li>前端隐藏按钮 ≠ 权限控制</li>
          <li>密码 bcrypt 哈希存储</li>
          <li>敏感操作记审计日志</li>
        </ul>
      </div>
      <div style={{ marginTop: 16 }}>
        <EmptyState
          title="用户列表（占位）"
          message="接入真实数据库和认证后，此处将展示用户列表。"
        />
      </div>
    </AppShell>
  );
}
