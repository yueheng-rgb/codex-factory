import { success, errorResponse } from "@/lib/api-response";
import { getRecordById, updateRecord } from "@/lib/records";

export async function GET(
  _request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const record = getRecordById(params.id);
    if (!record) {
      return errorResponse("NOT_FOUND", "记录不存在");
    }
    return Response.json(success(record));
  } catch {
    return errorResponse("INTERNAL_ERROR", "服务器错误");
  }
}

export async function PATCH(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const record = getRecordById(params.id);
    if (!record) {
      return errorResponse("NOT_FOUND", "记录不存在");
    }

    const body = await request.json();
    const updated = updateRecord(params.id, {
      status: body.status ?? record.status,
      remark: body.remark !== undefined ? body.remark : record.remark,
    });

    if (!updated) {
      return errorResponse("NOT_FOUND", "记录不存在");
    }

    return Response.json(success(updated));
  } catch {
    return errorResponse("INTERNAL_ERROR", "服务器错误");
  }
}
