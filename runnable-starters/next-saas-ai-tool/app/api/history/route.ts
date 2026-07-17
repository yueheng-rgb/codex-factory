import { success, errorResponse } from "@/lib/api-response";
import { getHistory } from "@/lib/generation-history";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = Math.max(1, parseInt(searchParams.get("page") || "1"));
    const pageSize = Math.min(100, Math.max(1, parseInt(searchParams.get("pageSize") || searchParams.get("limit") || "20")));
    const result = getHistory("u-002", page, pageSize);
    return Response.json(success(result.items, {
      page: result.page, limit: result.pageSize, total: result.total, totalPages: result.totalPages,
    }));
  } catch {
    return errorResponse("INTERNAL_ERROR", "Server error");
  }
}