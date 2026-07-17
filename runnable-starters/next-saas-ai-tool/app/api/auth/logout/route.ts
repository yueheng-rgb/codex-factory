import { success } from "@/lib/api-response";
import { destroySession } from "@/lib/mock-session";

export async function POST() {
  await destroySession();
  return Response.json(success({ message: "Logged out" }));
}