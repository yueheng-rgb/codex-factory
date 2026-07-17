"use client";

import { ReactNode } from "react";
import Sidebar from "./Sidebar";

interface AppShellProps {
  /** 页面标题 */
  title?: string;
  /** 当前用户角色（用于 Sidebar 权限过滤） */
  role?: "admin" | "user";
  /** 子页面内容 */
  children: ReactNode;
}

export default function AppShell({ title, role = "user", children }: AppShellProps) {
  return (
    <div className="app-shell">
      <Sidebar role={role} />
      <div className="app-main">
        <header className="app-topbar">
          <h1 className="app-topbar-title">{title ?? "PROJECT_NAME"}</h1>
          <div className="app-topbar-actions">
            <span className="app-role-badge">{role === "admin" ? "管理员" : "用户"}</span>
            <a href="/login" className="btn-text">退出</a>
          </div>
        </header>
        <main className="app-content">{children}</main>
      </div>
    </div>
  );
}
