"use client";

import { useEffect, useState } from "react";
import AppShell from "@/components/AppShell";
import UsageCard from "@/components/UsageCard";
import LoadingState from "@/components/LoadingState";
import ErrorState from "@/components/ErrorState";

export default function AccountPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [quota, setQuota] = useState<{ total: number; used: number } | null>(null);

  function load() {
    setLoading(true); setError(false);
    fetch("/api/usage").then((r) => r.json())
      .then((j) => { if (!j.ok) throw new Error(j.error?.message); setQuota(j.data); })
      .catch(() => setError(true)).finally(() => setLoading(false));
  }
  useEffect(() => { load(); }, []);

  return (
    <AppShell title="我的账户" role="user">
      {loading && <LoadingState />}
      {error && <ErrorState onRetry={load} />}
      {quota && !loading && !error && (
        <div>
          <UsageCard total={quota.total} used={quota.used} remaining={quota.total - quota.used} />
          <div className="panel" style={{ marginTop: 16 }}>
            <h3 style={{ marginBottom: 8 }}>账户信息</h3>
            <p style={{ color: "#666", fontSize: 14 }}>用户：user</p>
            <p style={{ color: "#888", fontSize: 13, marginTop: 8 }}>
              ⚠️ 真实项目应在服务端处理额度和账户信息。额度变动必须用条件 UPDATE + 事务保护。
            </p>
          </div>
        </div>
      )}
    </AppShell>
  );
}
