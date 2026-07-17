interface StatusBadgeProps {
  status: string;
  /** 自定义标签映射 */
  labels?: Record<string, string>;
}

const DEFAULT_LABELS: Record<string, string> = {
  pending: "待处理",
  active: "进行中",
  completed: "已完成",
  archived: "已归档",
  cancelled: "已取消",
  disabled: "已禁用",
  error: "异常",
};

export default function StatusBadge({ status, labels }: StatusBadgeProps) {
  const labelMap = { ...DEFAULT_LABELS, ...labels };
  const label = labelMap[status] || status;
  return <span className={`badge badge-${status}`}>{label}</span>;
}
