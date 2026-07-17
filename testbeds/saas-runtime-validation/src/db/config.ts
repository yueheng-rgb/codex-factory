// Database configuration for SaaS Runtime Validation
// Supports: in-memory (test mode, default) and Postgres (production-like mode)

export interface DbConfig {
  type: "memory" | "postgres";
  connectionString?: string;
}

export function getDbConfig(): DbConfig {
  const url = process.env.DATABASE_URL;
  if (url && url.startsWith("postgres")) {
    return { type: "postgres", connectionString: url };
  }
  return { type: "memory" };
}

// Migration command: npx tsx src/db/migrate.ts
// Seed command: npx tsx src/db/seed.ts
// Test mode (default): uses in-memory Map stores — no Postgres needed
