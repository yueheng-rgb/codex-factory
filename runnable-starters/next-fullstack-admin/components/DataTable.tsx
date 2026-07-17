import type { BusinessRecord } from "@/lib/mock-db";

interface DataTableProps {
  records: BusinessRecord[];
  /** 为空时展示 EmptyState */
  emptyMessage?: string;
}

const STATUS_LABELS: Record<string, string> = {
  pending: "待处理",
  active: "进行中",
  completed: "已完成",
  archived: "已归档",
  cancelled: "已取消",
};

const PRIORITY_LABELS: Record<string, string> = {
  high: "高",
  medium: "中",
  low: "低",
};

export default function DataTable({ records, emptyMessage = "暂无记录" }: DataTableProps) {
  if (records.length === 0) {
    return <div className="empty-table">📋 {emptyMessage}</div>;
  }

  return (
    <div className="table-wrapper">
      <table className="table">
        <thead>
          <tr>
            <th>标题</th>
            <th>状态</th>
            <th>优先级</th>
            <th>创建者</th>
            <th>更新时间</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          {records.map((r) => (
            <tr key={r.id}>
              <td>
                <a href={`/records/${r.id}`} className="table-link">
                  {r.title}
                </a>
              </td>
              <td>
                <span className={`badge badge-${r.status}`}>
                  {STATUS_LABELS[r.status] || r.status}
                </span>
              </td>
              <td>
                <span className={`badge badge-priority-${r.priority}`}>
                  {PRIORITY_LABELS[r.priority] || r.priority}
                </span>
              </td>
              <td className="text-muted">{r.createdBy}</td>
              <td className="text-muted">{new Date(r.updatedAt).toLocaleDateString("zh-CN")}</td>
              <td>
                <a href={`/records/${r.id}`} className="btn-text">
                  查看
                </a>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
