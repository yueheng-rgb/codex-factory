import type { UseCase } from "../data/siteContent";

interface UseCasesProps {
  title: string;
  useCases: UseCase[];
}

export default function UseCases({ title, useCases }: UseCasesProps) {
  return (
    <section id="use-cases" className="section">
      <div className="section-inner">
        <h2 className="section-title">{title}</h2>
        <div className="usecases-grid">
          {useCases.map((uc, i) => (
            <div key={i} className="usecase-card">
              <h3 className="usecase-title">{uc.title}</h3>
              <p className="usecase-desc">{uc.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
