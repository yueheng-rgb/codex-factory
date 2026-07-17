import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "PROJECT_NAME", description: "AI Tool" };
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="zh-CN"><body>{children}</body></html>;
}
