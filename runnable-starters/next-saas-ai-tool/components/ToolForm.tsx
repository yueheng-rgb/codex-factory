"use client";

import FormField from "./FormField";

interface ToolFormProps {
  topic: string;
  style: string;
  length: string;
  purpose: string;
  onTopicChange: (v: string) => void;
  onStyleChange: (v: string) => void;
  onLengthChange: (v: string) => void;
  onPurposeChange: (v: string) => void;
  onSubmit: () => void;
  submitting: boolean;
  error?: string;
  disabled?: boolean;
}

export default function ToolForm({
  topic, style, length, purpose,
  onTopicChange, onStyleChange, onLengthChange, onPurposeChange,
  onSubmit, submitting, error, disabled,
}: ToolFormProps) {
  return (
    <form
      onSubmit={(e) => { e.preventDefault(); onSubmit(); }}
      className="panel"
    >
      <h3 style={{ marginBottom: 16 }}>生成工具</h3>

      <FormField label="主题" required>
        <input
          className="input"
          value={topic}
          onChange={(e) => onTopicChange(e.target.value)}
          placeholder="输入生成主题..."
          disabled={submitting || disabled}
        />
      </FormField>

      <FormField label="风格（可选）">
        <input
          className="input"
          value={style}
          onChange={(e) => onStyleChange(e.target.value)}
          placeholder="如：正式 / 幽默 / 简洁"
          disabled={submitting}
        />
      </FormField>

      <FormField label="长度（可选）">
        <select
          className="input"
          value={length}
          onChange={(e) => onLengthChange(e.target.value)}
          disabled={submitting}
        >
          <option value="">默认</option>
          <option value="short">简短</option>
          <option value="medium">适中</option>
          <option value="long">详细</option>
        </select>
      </FormField>

      <FormField label="用途（可选）">
        <input
          className="input"
          value={purpose}
          onChange={(e) => onPurposeChange(e.target.value)}
          placeholder="如：营销文案 / 产品介绍 / 社交媒体"
          disabled={submitting}
        />
      </FormField>

      {error && <div className="form-alert form-alert-error">{error}</div>}

      <button
        className="btn btn-primary btn-full"
        type="submit"
        disabled={submitting || disabled || !topic.trim()}
      >
        {submitting ? "生成中..." : disabled ? "次数不足" : "开始生成"}
      </button>
    </form>
  );
}
