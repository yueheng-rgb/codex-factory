import { Tenant, User, Subscription, GenerationResult, ApiKey, BillingEvent } from "../types.js";

export const tenants = new Map<string, Tenant>();
export const users = new Map<string, User>();
export const subscriptions = new Map<string, Subscription>();
export const generations = new Map<string, GenerationResult>();
export const apiKeys = new Map<string, ApiKey>();
export const processedEvents = new Set<string>();
export const providerKeys = new Map<string, string>(); // provider → key, NEVER exposed

let nextId = 1;
export function gid(prefix: string): string { return `${prefix}-${nextId++}-${Date.now()}`; }
export function resetAll(): void {
  tenants.clear(); users.clear(); subscriptions.clear(); generations.clear();
  apiKeys.clear(); processedEvents.clear(); providerKeys.clear();
  nextId = 1;
}
