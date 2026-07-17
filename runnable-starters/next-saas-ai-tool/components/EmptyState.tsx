interface EmptyStateProps {
  title?: string;
  message?: string;
  actionLabel?: string;
  actionHref?: string;
}

export default function EmptyState({
  title = "暂无数据",
  message = "当前没有可显示的内容。",
  actionLabel,
  actionHref,
}: EmptyStateProps) {
  return (
    <div className="state-box">
      <div className="state-icon">📭</div>
      <h3 className="state-title">{title}</h3>
      <p className="state-desc">{message}</p>
      {actionLabel && actionHref && (
        <a href={actionHref} className="btn btn-primary">
          {actionLabel}
        </a>
      )}
    </div>
  );
}
