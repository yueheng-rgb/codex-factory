/**
 * Mock AI Provider — Generic SaaS text generation
 * Supports testable failure via forceFail parameter (dev/test/benchmark only).
 * Replace with real OpenAI/Anthropic API in production.
 */

export interface GenerateInput {
  prompt: string;
  topic?: string;
  style?: string;
  length?: number;
  purpose?: string;
  forceFail?: boolean;
}

export interface GenerateResult {
  id: string;
  content: string;
  model: string;
  usage: { promptTokens: number; completionTokens: number; totalTokens: number };
}

/**
 * Check if forceFail is allowed in the current environment.
 * Only permitted in development, test, or explicit benchmark mode.
 */
function isDevOrTest(): boolean {
  if (typeof process !== "undefined" && process.env.NODE_ENV === "production") return false;
  if (typeof process !== "undefined" && process.env.CODEX_BENCHMARK_MODE === "true") return true;
  return true; // development or test
}

/**
 * Mock generation function.
 * Set forceFail=true to simulate AI failure (only in dev/test/benchmark).
 * In production, forceFail is ignored.
 */
export async function mockGenerate(input: GenerateInput): Promise<GenerateResult> {
  // Testable failure path — dev/test/benchmark only
  if (input.forceFail && isDevOrTest()) {
    await new Promise((r) => setTimeout(r, 500));
    throw new Error("Mock AI failure triggered by forceFail flag");
  }

  await new Promise((r) => setTimeout(r, 800 + Math.random() * 800));

  const id = `gen-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

  const content = `Generated content based on prompt:\n${input.prompt}\n\n---\n*AI-generated | Model: mock-saas-v1*`;

  return {
    id,
    content,
    model: "mock-saas-v1",
    usage: { promptTokens: 120, completionTokens: 250, totalTokens: 370 },
  };
}
