"use client";

import { useEffect, useState } from "react";
import AppShell from "@/components/AppShell";
import UsageCard from "@/components/UsageCard";
import LoadingState from "@/components/LoadingState";
import ErrorState from "@/components/ErrorState";

export default function DashboardPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [quota, setQuota] = useState<{ total: number; used: number } | null>(null);

  function load() {
    setLoading(true); setError(false);
    fetch("/api/usage")
      .then((r) => r.json())
      .then((j) => { if (!j.ok) throw new Error(j.error?.message); setQuota(j.data); })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }
  useEffect(() => { load(); }, []);

  return (
    <AppShell title="控制台" role="user">
      {loading && <LoadingState />}
      {error && <ErrorState onRetry={load} />}
      {quota && !loading && !error && (
        <div>
          <UsageCard total={quota.total} used={quota.used} remaining={quota.total - quota.used} />
          <div style={{ marginTop: 16 }}>
            <a href="/tool" className="btn btn-primary">开始生成 →</a>
            <a href="/history" className="btn-text" style={{ marginLeft: 16 }}>查看历史</a>
          </div>
        </div>
      )}
    </AppShell>
  );
}
