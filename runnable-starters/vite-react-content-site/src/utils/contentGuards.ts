/**
 * 内容守卫工具
 * 防止复制 starter 后内容缺失导致页面崩溃。
 */

import type { SiteContent } from "../data/siteContent";

/**
 * 检查站点内容是否包含必要字段。
 * 复制 starter 后如果忘记填充内容，会返回 false。
 */
export function hasRequiredSiteContent(content: SiteContent): boolean {
  if (!content) return false;
  if (!content.siteName || content.siteName === "PROJECT_NAME") return false;
  if (!content.hero || !content.hero.title) return false;
  if (!content.features || content.features.length === 0) return false;
  return true;
}

/**
 * 安全获取文本，值为空时使用 fallback。
 */
export function safeText(value: string | undefined | null, fallback: string): string {
  if (!value || value.trim() === "") return fallback;
  return value;
}
