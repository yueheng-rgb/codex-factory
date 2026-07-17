interface UsageCardProps {
  total: number;
  used: number;
  remaining: number;
}

export default function UsageCard({ total, used, remaining }: UsageCardProps) {
  const pct = total > 0 ? Math.round((used / total) * 100) : 0;
  const low = remaining <= total * 0.2;

  return (
    <div className="panel">
      <h3 style={{ marginBottom: 12 }}>使用额度</h3>
      <div style={{ display: "flex", gap: 24, flexWrap: "wrap", marginBottom: 12 }}>
        <div><span style={{ fontSize: 32, fontWeight: 800, color: low ? "#e74c3c" : "#1a1a2e" }}>{remaining}</span><span style={{ color: "#888", marginLeft: 4 }}>剩余</span></div>
        <div><span style={{ color: "#888" }}>已用 {used} / 共 {total}</span></div>
      </div>
      <div style={{ background: "#eee", borderRadius: 99, height: 8, overflow: "hidden" }}>
        <div style={{ background: low ? "#e74c3c" : "#5b9aff", height: "100%", width: `${pct}%`, borderRadius: 99, transition: "width .3s" }} />
      </div>
      {low && <p style={{ marginTop: 8, fontSize: 13, color: "#e74c3c" }}>⚠️ 额度即将用尽</p>}
    </div>
  );
}
