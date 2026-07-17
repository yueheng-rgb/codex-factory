import type { HistoryRecord } from "@/lib/generation-history";

interface HistoryListProps {
  items: HistoryRecord[];
  emptyMessage?: string;
}

export default function HistoryList({ items, emptyMessage = "暂无生成记录" }: HistoryListProps) {
  if (items.length === 0) {
    return <div className="empty-table">📋 {emptyMessage}</div>;
  }

  return (
    <div className="table-wrapper">
      <table className="table">
        <thead>
          <tr>
            <th>主题</th>
            <th>状态</th>
            <th>模型</th>
            <th>时间</th>
          </tr>
        </thead>
        <tbody>
          {items.map((r) => (
            <tr key={r.id}>
              <td className="table-link">{r.topic}</td>
              <td>
                <span className={`badge ${r.status === "success" ? "badge-completed" : "badge-error"}`}>
                  {r.status === "success" ? "成功" : "失败"}
                </span>
              </td>
              <td className="text-muted">{r.model}</td>
              <td className="text-muted">{new Date(r.createdAt).toLocaleString("zh-CN")}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
