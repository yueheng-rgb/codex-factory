interface EmptyStateProps {
  /** 标题，如"暂无内容" */
  title?: string;
  /** 引导文案 */
  message?: string;
}

/**
 * 空状态组件（示例）
 * 用于数据为空的场景。默认首页不展示此组件。
 */
export default function EmptyState({
  title = "暂无内容",
  message = "当前没有可显示的数据。",
}: EmptyStateProps) {
  return (
    <div className="state-container">
      <div className="state-icon">📭</div>
      <h3 className="state-title">{title}</h3>
      <p className="state-message">{message}</p>
    </div>
  );
}
