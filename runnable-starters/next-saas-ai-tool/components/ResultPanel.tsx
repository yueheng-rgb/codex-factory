interface ResultPanelProps {
  content: string;
  model: string;
  promptTokens?: number;
  completionTokens?: number;
}

export default function ResultPanel({ content, model, promptTokens, completionTokens }: ResultPanelProps) {
  return (
    <div className="panel" style={{ marginTop: 24 }}>
      <h3 style={{ marginBottom: 12 }}>生成结果</h3>
      <div style={{
        background: "#f8f9fa", borderRadius: 8, padding: 16,
        whiteSpace: "pre-wrap", fontSize: 15, lineHeight: 1.7,
        maxHeight: 400, overflowY: "auto"
      }}>
        {content}
      </div>
      <div style={{ marginTop: 12, fontSize: 13, color: "#888" }}>
        模型：{model}
        {promptTokens != null && ` · 输入 ${promptTokens} tokens`}
        {completionTokens != null && ` · 输出 ${completionTokens} tokens`}
      </div>
    </div>
  );
}
