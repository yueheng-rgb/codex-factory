interface ErrorStateProps {
  /** 错误提示标题 */
  title?: string;
  /** 错误详情 */
  message?: string;
  /** 重试回调 */
  onRetry?: () => void;
}

/**
 * 错误状态组件（示例）
 * 用于数据加载失败等场景。默认首页不展示此组件。
 */
export default function ErrorState({
  title = "加载失败",
  message = "请检查网络连接后重试。",
  onRetry,
}: ErrorStateProps) {
  return (
    <div className="state-container">
      <div className="state-icon">⚠️</div>
      <h3 className="state-title">{title}</h3>
      <p className="state-message">{message}</p>
      {onRetry && (
        <button className="btn btn-secondary" onClick={onRetry}>
          重试
        </button>
      )}
    </div>
  );
}
