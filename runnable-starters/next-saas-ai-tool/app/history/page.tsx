"use client";

import { useEffect, useState, useCallback } from "react";
import AppShell from "@/components/AppShell";
import HistoryList from "@/components/HistoryList";
import LoadingState from "@/components/LoadingState";
import ErrorState from "@/components/ErrorState";
import type { HistoryRecord } from "@/lib/generation-history";

export default function HistoryPage() {
  const [items, setItems] = useState<HistoryRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  const load = useCallback(() => {
    setLoading(true); setError(false);
    fetch("/api/history?page=1&limit=50")
      .then((r) => r.json())
      .then((j) => { if (!j.ok) throw new Error(j.error?.message); setItems(j.data.items || []); })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }, []);
  useEffect(() => { load(); }, [load]);

  return (
    <AppShell title="生成历史" role="user">
      {loading && <LoadingState />}
      {error && <ErrorState onRetry={load} />}
      {!loading && !error && <HistoryList items={items} />}
    </AppShell>
  );
}
