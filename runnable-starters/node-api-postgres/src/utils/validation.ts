/**
 * 通用校验工具
 * 从 next-fullstack-admin 适配，Fastify 版本。
 */

export interface ValidationRule {
  required?: boolean;
  minLength?: number;
  maxLength?: number;
  pattern?: RegExp;
  message?: string;
}

export interface ValidationResult {
  valid: boolean;
  errors: Array<{ field: string; message: string }>;
}

export function validateField(
  field: string,
  value: string | undefined | null,
  rules: ValidationRule[]
): Array<{ field: string; message: string }> {
  const errors: Array<{ field: string; message: string }> = [];

  for (const rule of rules) {
    if (rule.required && (!value || value.trim() === "")) {
      errors.push({ field, message: rule.message || `${field} 不能为空` });
      continue;
    }
    if (value && rule.minLength && value.length < rule.minLength) {
      errors.push({ field, message: rule.message || `${field} 最少 ${rule.minLength} 个字符` });
    }
    if (value && rule.maxLength && value.length > rule.maxLength) {
      errors.push({ field, message: rule.message || `${field} 最多 ${rule.maxLength} 个字符` });
    }
    if (value && rule.pattern && !rule.pattern.test(value)) {
      errors.push({ field, message: rule.message || `${field} 格式不正确` });
    }
  }

  return errors;
}

export function validateFields(
  fields: Array<{ field: string; value: string | undefined | null; rules: ValidationRule[] }>
): ValidationResult {
  const errors = fields.flatMap(({ field, value, rules }) =>
    validateField(field, value, rules)
  );
  return { valid: errors.length === 0, errors };
}
