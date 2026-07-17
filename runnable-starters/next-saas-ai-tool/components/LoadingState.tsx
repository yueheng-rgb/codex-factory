interface LoadingStateProps {
  message?: string;
}

export default function LoadingState({ message = "加载中..." }: LoadingStateProps) {
  return (
    <div className="state-box">
      <div className="spinner" />
      <p className="state-desc">{message}</p>
    </div>
  );
}
