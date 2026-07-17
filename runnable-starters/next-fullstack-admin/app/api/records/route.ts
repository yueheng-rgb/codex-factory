import { success, errorResponse } from "@/lib/api-response";
import { queryRecords, createRecord } from "@/lib/records";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const q = {
      page: parseInt(searchParams.get("page") || "1"),
      limit: parseInt(searchParams.get("limit") || "20"),
      search: searchParams.get("search") || undefined,
      status: searchParams.get("status") || undefined,
      priority: searchParams.get("priority") || undefined,
    };

    const result = queryRecords(q);
    return Response.json(success(result.items, {
      page: result.page,
      limit: result.limit,
      total: result.total,
      totalPages: result.totalPages,
    }));
  } catch {
    return errorResponse("INTERNAL_ERROR", "服务器错误");
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();

    // 服务端校验
    const errors: Array<{ field: string; message: string }> = [];
    if (!body.title?.trim()) errors.push({ field: "title", message: "标题不能为空" });
    if (!body.description?.trim()) errors.push({ field: "description", message: "描述不能为空" });
    if (errors.length > 0) {
      return errorResponse("VALIDATION_ERROR", "输入校验失败", errors);
    }

    const record = createRecord({
      title: body.title.trim(),
      description: body.description.trim(),
      status: body.status || "pending",
      priority: body.priority || "medium",
      createdBy: "mock-user",
    });

    return Response.json(success(record), { status: 201 });
  } catch {
    return errorResponse("INTERNAL_ERROR", "服务器错误");
  }
}
