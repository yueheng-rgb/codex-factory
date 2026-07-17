"use client";

import { usePathname } from "next/navigation";

interface SidebarProps {
  role?: "admin" | "user";
}

interface NavItem {
  label: string;
  href: string;
  adminOnly?: boolean;
}

const NAV_ITEMS: NavItem[] = [
  { label: "仪表盘", href: "/dashboard" },
  { label: "记录管理", href: "/records" },
  { label: "用户管理", href: "/settings/users", adminOnly: true },
];

export default function Sidebar({ role = "user" }: SidebarProps) {
  const pathname = usePathname();

  const visibleItems = NAV_ITEMS.filter(
    (item) => !item.adminOnly || role === "admin"
  );

  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <a href="/dashboard" className="sidebar-logo">
          PROJECT_NAME
        </a>
      </div>
      <nav className="sidebar-nav">
        {visibleItems.map((item) => {
          const isActive = pathname === item.href || pathname.startsWith(item.href + "/");
          return (
            <a
              key={item.href}
              href={item.href}
              className={`sidebar-link${isActive ? " sidebar-link-active" : ""}`}
            >
              {item.label}
            </a>
          );
        })}
      </nav>
      <div className="sidebar-footer">
        <span className="sidebar-role-text">
          {role === "admin" ? "管理员" : "普通用户"}
        </span>
      </div>
    </aside>
  );
}
