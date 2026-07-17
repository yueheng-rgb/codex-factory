import {
  defaultSiteContent,
} from "./data/siteContent";
import Header from "./components/Header";
import Hero from "./components/Hero";
import Features from "./components/Features";
import HowItWorks from "./components/HowItWorks";
import UseCases from "./components/UseCases";
import CTA from "./components/CTA";
import Footer from "./components/Footer";

export default function App() {
  const content = defaultSiteContent;

  return (
    <div className="app">
      <Header siteName={content.siteName} nav={content.nav} />
      <main>
        <Hero hero={content.hero} />
        <Features title={content.featuresTitle} features={content.features} />
        <HowItWorks title={content.stepsTitle} steps={content.steps} />
        <UseCases title={content.useCasesTitle} useCases={content.useCases} />
        <CTA
          text={content.ctaText}
          subtext={content.ctaSubtext}
          buttonText={content.ctaButtonText}
        />
      </main>
      <Footer text={content.footerText} links={content.footerLinks} />
    </div>
  );
}
