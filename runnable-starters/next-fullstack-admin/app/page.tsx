import { redirect } from "next/navigation";

/** 根路由 → 重定向到仪表盘 */
export default function RootPage() {
  redirect("/dashboard");
}
