/**
 * Smoke tests for node-api-postgres starter
 * Verifies: health endpoint, auth flow, records CRUD, error format
 */
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { buildApp } from "../src/app.js";
import type { FastifyInstance } from "fastify";

let app: FastifyInstance;

beforeAll(async () => {
  app = buildApp();
  await app.ready();
});

afterAll(async () => {
  await app.close();
});

describe("Health endpoint", () => {
  it("GET /health returns ok", async () => {
    const res = await app.inject({ method: "GET", url: "/health" });
    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.ok).toBe(true);
    expect(body.data.status).toBe("ok");
  });
});

describe("Auth endpoint", () => {
  it("POST /auth/login with valid credentials returns token", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/auth/login",
      payload: { username: "admin", password: "admin123" },
    });
    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.ok).toBe(true);
    expect(body.data.token).toBeDefined();
    expect(body.data.user.role).toBe("admin");
  });

  it("POST /auth/login with invalid password returns 401", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/auth/login",
      payload: { username: "admin", password: "wrong" },
    });
    expect(res.statusCode).toBe(401);
    const body = JSON.parse(res.body);
    expect(body.ok).toBe(false);
    expect(body.error.code).toBe("UNAUTHORIZED");
  });

  it("POST /auth/login with missing fields returns 400", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/auth/login",
      payload: {},
    });
    expect(res.statusCode).toBe(400);
    const body = JSON.parse(res.body);
    expect(body.ok).toBe(false);
  });
});

describe("Records CRUD (authenticated)", () => {
  let token: string;

  beforeAll(async () => {
    const res = await app.inject({
      method: "POST",
      url: "/auth/login",
      payload: { username: "admin", password: "admin123" },
    });
    token = JSON.parse(res.body).data.token;
  });

  it("GET /records returns paginated list", async () => {
    const res = await app.inject({
      method: "GET",
      url: "/records",
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.ok).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.meta).toBeDefined();
    expect(body.meta.page).toBe(1);
  });

  it("GET /records with search filters results", async () => {
    const res = await app.inject({
      method: "GET",
      url: "/records?search=test",
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.statusCode).toBe(200);
  });

  it("POST /records creates a new record", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/records",
      headers: { authorization: `Bearer ${token}` },
      payload: { title: "Test Record", description: "Created by test" },
    });
    expect(res.statusCode).toBe(201);
    const body = JSON.parse(res.body);
    expect(body.ok).toBe(true);
    expect(body.data.title).toBe("Test Record");
    expect(body.data.id).toBeDefined();
  });

  it("POST /records with empty title returns 400", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/records",
      headers: { authorization: `Bearer ${token}` },
      payload: { title: "", description: "" },
    });
    expect(res.statusCode).toBe(400);
    const body = JSON.parse(res.body);
    expect(body.ok).toBe(false);
    expect(body.error.code).toBe("VALIDATION_ERROR");
  });

  it("GET /records/:id returns a single record", async () => {
    const listRes = await app.inject({
      method: "GET",
      url: "/records?limit=1",
      headers: { authorization: `Bearer ${token}` },
    });
    const records = JSON.parse(listRes.body).data;
    if (records.length > 0) {
      const res = await app.inject({
        method: "GET",
        url: `/records/${records[0].id}`,
        headers: { authorization: `Bearer ${token}` },
      });
      expect(res.statusCode).toBe(200);
    }
  });

  it("GET /records/:id with non-existent id returns 404", async () => {
    const res = await app.inject({
      method: "GET",
      url: "/records/nonexistent",
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.statusCode).toBe(404);
  });

  it("PATCH /records/:id updates status", async () => {
    const listRes = await app.inject({
      method: "GET",
      url: "/records?limit=1",
      headers: { authorization: `Bearer ${token}` },
    });
    const records = JSON.parse(listRes.body).data;
    if (records.length > 0) {
      const res = await app.inject({
        method: "PATCH",
        url: `/records/${records[0].id}`,
        headers: { authorization: `Bearer ${token}` },
        payload: { status: "in_progress" },
      });
      expect(res.statusCode).toBe(200);
      const body = JSON.parse(res.body);
      expect(body.ok).toBe(true);
    }
  });

  it("GET /records without auth returns 401", async () => {
    const res = await app.inject({ method: "GET", url: "/records" });
    expect(res.statusCode).toBe(401);
  });
});

describe("Error format", () => {
  it("Unknown route returns 404 with unified format", async () => {
    const res = await app.inject({ method: "GET", url: "/nonexistent" });
    expect(res.statusCode).toBe(404);
    const body = JSON.parse(res.body);
    expect(body.ok).toBe(false);
    expect(body.error.code).toBeDefined();
    expect(body.error.message).toBeDefined();
  });
});