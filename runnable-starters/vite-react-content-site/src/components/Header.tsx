import type { NavItem } from "../data/siteContent";
import { safeText } from "../utils/contentGuards";

interface HeaderProps {
  siteName: string;
  nav: NavItem[];
}

export default function Header({ siteName, nav }: HeaderProps) {
  return (
    <header className="header">
      <div className="header-inner">
        <a href="#" className="header-logo">
          {safeText(siteName, "Site Name")}
        </a>
        <nav className="header-nav">
          {nav.map((item) => (
            <a key={item.href} href={item.href} className="header-nav-link">
              {item.label}
            </a>
          ))}
        </nav>
      </div>
    </header>
  );
}
