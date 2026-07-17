"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import AppShell from "@/components/AppShell";
import LoadingState from "@/components/LoadingState";
import ErrorState from "@/components/ErrorState";
import StatusBadge from "@/components/StatusBadge";
import ConfirmDialog from "@/components/ConfirmDialog";
import type { BusinessRecord } from "@/lib/mock-db";

export default function RecordDetailPage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;

  const [record, setRecord] = useState<BusinessRecord | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [notFound, setNotFound] = useState(false);
  const [updating, setUpdating] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [newStatus, setNewStatus] = useState("");
  const [remark, setRemark] = useState("");

  function load() {
    setLoading(true);
    setError(false);
    setNotFound(false);
    fetch(`/api/records/${id}`)
      .then((r) => r.json())
      .then((json) => {
        if (!json.ok) {
          if (json.error?.code === "NOT_FOUND") { setNotFound(true); return; }
          throw new Error(json.error?.message);
        }
        setRecord(json.data);
        setRemark(json.data.remark || "");
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, [id]);

  function openStatusChange(status: string) {
    setNewStatus(status);
    setConfirmOpen(true);
  }

  async function confirmStatusChange() {
    setUpdating(true);
    try {
      const res = await fetch(`/api/records/${id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus, remark }),
      });
      const json = await res.json();
      if (!json.ok) { alert(json.error?.message || "修改失败"); return; }
      setRecord(json.data);
      setConfirmOpen(false);
    } finally {
      setUpdating(false);
    }
  }

  return (
    <AppShell title="记录详情" role="admin">
      {loading && <LoadingState />}
      {notFound && (
        <ErrorState title="记录不存在" message="该记录可能已被删除，或 ID 不存在。" />
      )}
      {error && <ErrorState onRetry={load} />}
      {record && !loading && !error && !notFound && (
        <div className="detail-layout">
          <a href="/records" className="btn-text" style={{ marginBottom: 16, display: "inline-block" }}>
            ← 返回列表
          </a>
          <div className="panel">
            <h2 style={{ marginBottom: 12 }}>{record.title}</h2>
            <StatusBadge status={record.status} />
            <p style={{ marginTop: 16, color: "#555" }}>{record.description}</p>

            <div className="detail-meta" style={{ marginTop: 24 }}>
              <div><strong>优先级：</strong>{record.priority}</div>
              <div><strong>创建时间：</strong>{new Date(record.createdAt).toLocaleString("zh-CN")}</div>
              <div><strong>更新时间：</strong>{new Date(record.updatedAt).toLocaleString("zh-CN")}</div>
              {record.remark && <div><strong>备注：</strong>{record.remark}</div>}
            </div>

            <div style={{ marginTop: 24 }}>
              <h4 style={{ marginBottom: 8 }}>修改状态</h4>
              <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                {["pending", "active", "completed", "archived", "cancelled"].map((s) => (
                  <button
                    key={s}
                    className={`btn btn-sm ${record.status === s ? "btn-primary" : "btn-secondary"}`}
                    disabled={record.status === s || updating}
                    onClick={() => openStatusChange(s)}
                  >
                    {s === "pending" ? "待处理" :
                     s === "active" ? "进行中" :
                     s === "completed" ? "已完成" :
                     s === "archived" ? "归档" : "取消"}
                  </button>
                ))}
              </div>
              {updating && <p style={{ marginTop: 8, color: "#888" }}>更新中...</p>}
            </div>
          </div>

          <ConfirmDialog
            open={confirmOpen}
            title="确认修改状态"
            message={`确定要将状态修改为「${newStatus}」吗？`}
            confirmLabel="确认修改"
            onConfirm={confirmStatusChange}
            onCancel={() => setConfirmOpen(false)}
          />
        </div>
      )}
    </AppShell>
  );
}
