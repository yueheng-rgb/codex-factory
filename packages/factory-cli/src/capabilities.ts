import type { AgentCapability, AgentProfile, FactoryTask } from "./types.js";

export const ALL_AGENT_CAPABILITIES = new Set<AgentCapability>([
  "routing", "architecture", "product-design", "app-classification",
  "anti-overengineering", "knowledge-retrieval", "skill-curation",
  "source-verification", "independent-verification", "security-review",
  "drift-audit", "scope-audit", "contract-audit", "web-research",
  "documentation-research", "evidence-pack", "implementation", "frontend",
  "backend", "database", "auth-security", "mobile", "testing",
  "e2e-testing", "smoke-testing", "negative-testing", "integration",
  "conflict-resolution", "release",
]);

export const DOMAIN_SKILL_IDS = [
  "anti-overengineering",
  "app-type-classifier",
  "auth-permission-security",
  "backend-api-design",
  "database-schema-design",
  "frontend-ui-system",
  "mobile-miniapp-patterns",
  "product-architecture",
  "webapp-preview-testing",
] as const;

const CAPABILITY_SKILLS: Partial<Record<AgentCapability, string[]>> = {
  routing: ["app-type-classifier", "product-architecture", "anti-overengineering"],
  architecture: ["product-architecture", "anti-overengineering"],
  "product-design": ["product-architecture"],
  "app-classification": ["app-type-classifier"],
  "anti-overengineering": ["anti-overengineering"],
  frontend: ["frontend-ui-system"],
  backend: ["backend-api-design"],
  database: ["database-schema-design"],
  "auth-security": ["auth-permission-security"],
  "security-review": ["auth-permission-security"],
  mobile: ["mobile-miniapp-patterns"],
  testing: ["webapp-preview-testing"],
  "e2e-testing": ["webapp-preview-testing"],
  "smoke-testing": ["webapp-preview-testing"],
  "negative-testing": ["webapp-preview-testing"],
};

function inferredCapabilities(task: FactoryTask, profile: AgentProfile): AgentCapability[] {
  const text = (task.role + " " + task.title + " " + task.description).toLowerCase();
  const inferred: AgentCapability[] = [];
  if (profile.profile_id === "factory_router") {
    inferred.push("routing", "architecture", "anti-overengineering");
  }
  if (profile.profile_id === "factory_tester" || profile.profile_id === "factory_verifier") {
    inferred.push("testing");
  }
  if (/(front[ -]?end|react|vue|ui|页面|界面)/i.test(text)) inferred.push("frontend");
  if (/(back[ -]?end|api|server|后端|接口)/i.test(text)) inferred.push("backend");
  if (/(database|schema|sql|postgres|数据库|表结构)/i.test(text)) inferred.push("database");
  if (/(auth|permission|security|login|权限|鉴权|登录|安全)/i.test(text)) {
    inferred.push("auth-security");
  }
  if (/(mobile|miniapp|wechat|小程序|移动端|安卓|ios)/i.test(text)) inferred.push("mobile");
  return inferred;
}

export function skillIdsForTask(task: FactoryTask, profile: AgentProfile): string[] {
  const capabilities = task.required_capabilities?.length
    ? task.required_capabilities
    : inferredCapabilities(task, profile);
  return [...new Set(capabilities.flatMap((capability) => CAPABILITY_SKILLS[capability] ?? []))];
}
