import { success } from "@/lib/api-response"; export async function GET() { return Response.json(success({ status: "ok" })); }
