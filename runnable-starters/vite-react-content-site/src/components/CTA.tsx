interface CTAProps {
  text: string;
  subtext: string;
  buttonText: string;
}

export default function CTA({ text, subtext, buttonText }: CTAProps) {
  return (
    <section id="cta" className="section section-cta">
      <div className="section-inner">
        <h2 className="section-title">{text}</h2>
        <p className="cta-subtext">{subtext}</p>
        <a
          href={`mailto:${import.meta.env.VITE_CONTACT_EMAIL || "hello@example.com"}`}
          className="btn btn-primary"
        >
          {buttonText}
        </a>
      </div>
    </section>
  );
}
