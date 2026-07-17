import type { Feature } from "../data/siteContent";

interface FeaturesProps {
  title: string;
  features: Feature[];
}

export default function Features({ title, features }: FeaturesProps) {
  return (
    <section id="features" className="section">
      <div className="section-inner">
        <h2 className="section-title">{title}</h2>
        <div className="features-grid">
          {features.map((f, i) => (
            <div key={i} className="feature-card">
              <h3 className="feature-title">{f.title}</h3>
              <p className="feature-desc">{f.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
