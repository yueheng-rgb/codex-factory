"use client";

import { useState } from "react";
import AppShell from "@/components/AppShell";
import ToolForm from "@/components/ToolForm";
import ResultPanel from "@/components/ResultPanel";
import ErrorState from "@/components/ErrorState";

export default function ToolPage() {
  const [topic, setTopic] = useState("");
  const [style, setStyle] = useState("");
  const [length, setLength] = useState("");
  const [purpose, setPurpose] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [result, setResult] = useState<{ content: string; model: string } | null>(null);
  const [quotaExhausted, setQuotaExhausted] = useState(false);

  async function handleSubmit() {
    if (!topic.trim() || submitting) return;
    setError(""); setResult(null); setQuotaExhausted(false);
    setSubmitting(true);

    try {
      const res = await fetch("/api/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ topic: topic.trim(), style: style.trim() || undefined, length: length || undefined, purpose: purpose.trim() || undefined }),
      });
      const json = await res.json();
      if (!json.ok) {
        if (json.error?.code === "QUOTA_EXHAUSTED") { setQuotaExhausted(true); return; }
        setError(json.error?.message || "生成失败"); return;
      }
      setResult(json.data);
    } catch {
      setError("网络异常，请重试");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AppShell title="生成工具" role="user">
      <ToolForm
        topic={topic} style={style} length={length} purpose={purpose}
        onTopicChange={setTopic} onStyleChange={setStyle}
        onLengthChange={setLength} onPurposeChange={setPurpose}
        onSubmit={handleSubmit} submitting={submitting}
        error={error} disabled={quotaExhausted}
      />
      {result && (
        <ResultPanel content={result.content} model={result.model} />
      )}
      {quotaExhausted && (
        <div style={{ marginTop: 16 }}>
          <ErrorState title="次数不足" message="你的使用次数已用完，请联系管理员增加额度。" />
        </div>
      )}
    </AppShell>
  );
}
