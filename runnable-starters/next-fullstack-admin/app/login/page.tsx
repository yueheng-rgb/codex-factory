"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import FormField from "@/components/FormField";

export default function LoginPage() {
  const router = useRouter();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [errors, setErrors] = useState<{ username?: string; password?: string }>({});
  const [submitting, setSubmitting] = useState(false);
  const [loginError, setLoginError] = useState("");

  function validate(): boolean {
    const e: typeof errors = {};
    if (!username.trim()) e.username = "请输入用户名";
    if (!password.trim()) e.password = "请输入密码";
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoginError("");
    if (!validate()) return;

    setSubmitting(true);
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });
      const json = await res.json();
      if (!json.ok) {
        setLoginError(json.error?.message || "登录失败");
        return;
      }
      // Mock: 存储 token 并跳转
      localStorage.setItem("token", json.data.token);
      router.push("/dashboard");
    } catch {
      setLoginError("网络异常，请重试");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="login-page">
      <form className="login-form" onSubmit={handleSubmit}>
        <h1 className="login-title">PROJECT_NAME</h1>
        <p className="login-subtitle">管理后台登录</p>

        <FormField label="用户名" required error={errors.username}>
          <input
            className="input"
            type="text"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            placeholder="请输入用户名"
          />
        </FormField>

        <FormField label="密码" required error={errors.password}>
          <input
            className="input"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="请输入密码"
          />
        </FormField>

        {loginError && <div className="form-alert form-alert-error">{loginError}</div>}

        <button className="btn btn-primary btn-full" type="submit" disabled={submitting}>
          {submitting ? "登录中..." : "登录"}
        </button>

        <p className="login-hint">
          演示账号：admin / admin123 或 user / user123
        </p>
      </form>
    </div>
  );
}
