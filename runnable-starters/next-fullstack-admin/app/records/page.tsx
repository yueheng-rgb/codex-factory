"use client";

import { useEffect, useState, useCallback } from "react";
import AppShell from "@/components/AppShell";
import DataTable from "@/components/DataTable";
import SearchAndFilterBar from "@/components/SearchAndFilterBar";
import LoadingState from "@/components/LoadingState";
import ErrorState from "@/components/ErrorState";
import type { BusinessRecord } from "@/lib/mock-db";

const STATUS_OPTIONS = [
  { value: "pending", label: "待处理" },
  { value: "active", label: "进行中" },
  { value: "completed", label: "已完成" },
  { value: "archived", label: "已归档" },
  { value: "cancelled", label: "已取消" },
];

export default function RecordsPage() {
  const [records, setRecords] = useState<BusinessRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("");

  const load = useCallback(() => {
    setLoading(true);
    setError(false);
    const params = new URLSearchParams({ page: "1", limit: "100" });
    if (search) params.set("search", search);
    if (status) params.set("status", status);

    fetch(`/api/records?${params}`)
      .then((r) => r.json())
      .then((json) => {
        if (!json.ok) throw new Error(json.error?.message);
        setRecords(json.data.items || []);
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }, [search, status]);

  useEffect(() => { load(); }, [load]);

  function clearFilters() {
    setSearch("");
    setStatus("");
  }

  return (
    <AppShell title="记录管理" role="admin">
      <SearchAndFilterBar
        searchValue={search}
        onSearchChange={setSearch}
        statusValue={status}
        onStatusChange={setStatus}
        onClear={clearFilters}
        statusOptions={STATUS_OPTIONS}
      />
      <div style={{ marginTop: 16 }}>
        {loading && <LoadingState />}
        {error && <ErrorState onRetry={load} />}
        {!loading && !error && (
          <DataTable records={records} emptyMessage="暂无记录，请新建或调整筛选条件。" />
        )}
      </div>
    </AppShell>
  );
}
