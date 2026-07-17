/**
 * 站点内容配置
 * 所有页面内容集中管理，组件只负责渲染。
 * 修改此文件即可替换整个网站的内容。
 */

export interface NavItem {
  label: string;
  href: string;
}

export interface HeroContent {
  title: string;
  subtitle: string;
  ctaText: string;
  ctaHref: string;
}

export interface Feature {
  title: string;
  description: string;
}

export interface Step {
  step: number;
  title: string;
  description: string;
}

export interface UseCase {
  title: string;
  description: string;
}

export interface FooterLink {
  label: string;
  href: string;
}

export interface SiteContent {
  /** 网站名称，会显示在 Header 和浏览器标题 */
  siteName: string;
  /** Header 导航项 */
  nav: NavItem[];
  /** Hero 区域内容 */
  hero: HeroContent;
  /** 核心功能列表（建议 3-6 个） */
  features: Feature[];
  /** 功能区域标题 */
  featuresTitle: string;
  /** 使用步骤 */
  steps: Step[];
  /** 步骤区域标题 */
  stepsTitle: string;
  /** 适用场景 */
  useCases: UseCase[];
  /** 场景区域标题 */
  useCasesTitle: string;
  /** CTA 区域 */
  ctaText: string;
  ctaSubtext: string;
  ctaButtonText: string;
  /** Footer */
  footerText: string;
  footerLinks: FooterLink[];
}

/**
 * 默认 placeholder 内容。
 * 使用本 starter 时，替换整个对象为你自己的内容。
 */
export const defaultSiteContent: SiteContent = {
  siteName: "PROJECT_NAME",

  nav: [
    { label: "功能", href: "#features" },
    { label: "使用流程", href: "#how-it-works" },
    { label: "适用场景", href: "#use-cases" },
    { label: "联系我们", href: "#cta" },
  ],

  hero: {
    title: "一句话价值主张",
    subtitle:
      "用一句话说明你的产品/服务能为用户解决什么问题。这是用户看到的第一句话，确保它清晰、有吸引力。",
    ctaText: "开始使用",
    ctaHref: "#cta",
  },

  featuresTitle: "核心功能",
  features: [
    {
      title: "功能一",
      description: "简要描述这个功能如何帮助用户。每项功能用一两句话说清楚。",
    },
    {
      title: "功能二",
      description: "简要描述这个功能如何帮助用户。每项功能用一两句话说清楚。",
    },
    {
      title: "功能三",
      description: "简要描述这个功能如何帮助用户。每项功能用一两句话说清楚。",
    },
    {
      title: "功能四",
      description: "简要描述这个功能如何帮助用户。每项功能用一两句话说清楚。",
    },
  ],

  stepsTitle: "使用流程",
  steps: [
    { step: 1, title: "第一步", description: "描述用户需要做的第一步操作。" },
    { step: 2, title: "第二步", description: "描述用户需要做的第二步操作。" },
    { step: 3, title: "第三步", description: "描述用户需要做的第三步操作。" },
  ],

  useCasesTitle: "适用场景",
  useCases: [
    {
      title: "场景一",
      description: "描述在什么情况下适合使用你的产品/服务。",
    },
    {
      title: "场景二",
      description: "描述在什么情况下适合使用你的产品/服务。",
    },
    {
      title: "场景三",
      description: "描述在什么情况下适合使用你的产品/服务。",
    },
  ],

  ctaText: "准备好开始了吗？",
  ctaSubtext: "留下你的联系方式，我们会尽快与你联系。",
  ctaButtonText: "联系我们",

  footerText: `© ${new Date().getFullYear()} PROJECT_NAME. All Rights Reserved.`,
  footerLinks: [
    { label: "关于我们", href: "#" },
    { label: "联系方式", href: "#cta" },
    { label: "隐私政策", href: "#" },
  ],
};
