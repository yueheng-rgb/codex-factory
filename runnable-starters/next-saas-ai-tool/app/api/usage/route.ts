import { success } from "@/lib/api-response";
import { getQuota } from "@/lib/usage-quota";

export async function GET() {
  const q = getQuota("u-002");
  return Response.json(success({ total: q.total, used: q.used }));
}