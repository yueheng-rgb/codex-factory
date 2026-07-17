import type { HeroContent } from "../data/siteContent";

interface HeroProps {
  hero: HeroContent;
}

export default function Hero({ hero }: HeroProps) {
  return (
    <section className="hero">
      <div className="hero-inner">
        <h1 className="hero-title">{hero.title}</h1>
        <p className="hero-subtitle">{hero.subtitle}</p>
        <a href={hero.ctaHref} className="btn btn-primary">
          {hero.ctaText}
        </a>
      </div>
    </section>
  );
}
