import type { Step } from "../data/siteContent";

interface HowItWorksProps {
  title: string;
  steps: Step[];
}

export default function HowItWorks({ title, steps }: HowItWorksProps) {
  return (
    <section id="how-it-works" className="section section-alt">
      <div className="section-inner">
        <h2 className="section-title">{title}</h2>
        <div className="steps-list">
          {steps.map((s) => (
            <div key={s.step} className="step-item">
              <div className="step-number">{s.step}</div>
              <div>
                <h3 className="step-title">{s.title}</h3>
                <p className="step-desc">{s.description}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
