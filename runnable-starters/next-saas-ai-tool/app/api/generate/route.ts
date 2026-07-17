import { success, errorResponse } from "@/lib/api-response";
import { mockGenerate } from "@/lib/ai-provider-placeholder";
import { tryDeductQuota, restoreQuota, getRemaining } from "@/lib/usage-quota";
import { addHistory } from "@/lib/generation-history";
import { checkIdempotency, saveIdempotency, cleanExpiredIdempotency } from "@/lib/idempotency";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    if (!body.topic?.trim()) {
      return errorResponse("VALIDATION_ERROR", "Topic is required", [{ field: "topic", message: "Required" }]);
    }

    cleanExpiredIdempotency();
    const userId = "u-002";
    const idempotencyKey = body.idempotencyKey || `gen-${Date.now()}`;
    const cached = checkIdempotency(userId, "generate", idempotencyKey, JSON.stringify(body));
    if (cached.hit && !cached.conflict) return Response.json(success(cached.result));
    if (cached.hit && cached.conflict) return errorResponse("IDEMPOTENCY_CONFLICT", "Duplicate request with different payload");

    if (!tryDeductQuota(userId)) {
      return errorResponse("QUOTA_EXHAUSTED", "Quota exhausted");
    }

    let result;
    try {
      result = await mockGenerate({ prompt: body.topic.trim(),
        topic: body.topic.trim(),
        style: body.style?.trim(),
        length: body.length,
        purpose: body.purpose?.trim(),
      });
    } catch {
      restoreQuota(userId);
      return errorResponse("GENERATION_FAILED", "Generation failed, quota not deducted");
    }

    addHistory({ id: result.id, userId, prompt: body.topic.trim(), topic: body.topic.trim(),
      style: body.style?.trim(), content: result.content,
      model: result.model, status: "success", createdAt: new Date().toISOString() });

    saveIdempotency(userId, "generate", idempotencyKey, result, JSON.stringify(body));

    return Response.json(success({ ...result, remaining: getRemaining(userId) }));
  } catch {
    return errorResponse("INTERNAL_ERROR", "Server error");
  }
}