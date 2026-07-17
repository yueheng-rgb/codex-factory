import type { FooterLink } from "../data/siteContent";

interface FooterProps {
  text: string;
  links: FooterLink[];
}

export default function Footer({ text, links }: FooterProps) {
  return (
    <footer className="footer">
      <div className="footer-inner">
        <p className="footer-text">{text}</p>
        <nav className="footer-links">
          {links.map((link) => (
            <a key={link.href + link.label} href={link.href} className="footer-link">
              {link.label}
            </a>
          ))}
        </nav>
      </div>
    </footer>
  );
}
