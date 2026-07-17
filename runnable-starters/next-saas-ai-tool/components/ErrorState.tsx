"use client";

interface ErrorStateProps {
  title?: string;
  message?: string;
  onRetry?: () => void;
}

export default function ErrorState({
  title = "加载失败",
  message = "请检查网络连接后重试。",
  onRetry,
}: ErrorStateProps) {
  return (
    <div className="state-box">
      <div className="state-icon">⚠️</div>
      <h3 className="state-title">{title}</h3>
      <p className="state-desc">{message}</p>
      {onRetry && (
        <button className="btn btn-secondary" onClick={onRetry}>
          重试
        </button>
      )}
    </div>
  );
}
