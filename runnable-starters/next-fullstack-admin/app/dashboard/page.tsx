"use client";

import { useEffect, useState } from "react";
import AppShell from "@/components/AppShell";
import LoadingState from "@/components/LoadingState";
import ErrorState from "@/components/ErrorState";
import type { Role } from "@/lib/permissions";

interface DashboardStats {
  totalRecords: number;
  pendingRecords: number;
  activeRecords: number;
  completedRecords: number;
}

export default function DashboardPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const role: Role = "admin"; // Mock 角色

  function load() {
    setLoading(true);
    setError(false);
    fetch("/api/records?page=1&limit=1")
      .then((r) => r.json())
      .then((json) => {
        // 简化统计：从 mock-db 计算
        return fetch("/api/records?page=1&limit=100");
      })
      .then((r) => r.json())
      .then((json) => {
        if (!json.ok) throw new Error(json.error?.message);
        const items = json.data.items || [];
        setStats({
          totalRecords: json.data.total ?? items.length,
          pendingRecords: items.filter((i: { status: string }) => i.status === "pending").length,
          activeRecords: items.filter((i: { status: string }) => i.status === "active").length,
          completedRecords: items.filter((i: { status: string }) => i.status === "completed").length,
        });
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, []);

  return (
    <AppShell title="仪表盘" role={role}>
      {loading && <LoadingState />}
      {error && <ErrorState onRetry={load} />}
      {stats && !loading && !error && (
        <div>
          <div className="stats-grid">
            <div className="stat-card">
              <div className="stat-number">{stats.totalRecords}</div>
              <div className="stat-label">总记录</div>
            </div>
            <div className="stat-card stat-pending">
              <div className="stat-number">{stats.pendingRecords}</div>
              <div className="stat-label">待处理</div>
            </div>
            <div className="stat-card stat-active">
              <div className="stat-number">{stats.activeRecords}</div>
              <div className="stat-label">进行中</div>
            </div>
            <div className="stat-card stat-completed">
              <div className="stat-number">{stats.completedRecords}</div>
              <div className="stat-label">已完成</div>
            </div>
          </div>
          <div className="panel" style={{ marginTop: 24 }}>
            <h3 style={{ marginBottom: 8 }}>最近记录</h3>
            <a href="/records" className="btn-text">查看全部 →</a>
          </div>
        </div>
      )}
    </AppShell>
  );
}
