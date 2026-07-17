import { success, errorResponse } from "@/lib/api-response";
import { mockLogin } from "@/lib/auth-placeholder";

export async function POST(request: Request) {
  try {
    const { username, password } = await request.json();

    if (!username || !password) {
      return errorResponse("VALIDATION_ERROR", "用户名和密码不能为空", [
        ...( !username ? [{ field: "username", message: "请输入用户名" }] : []),
        ...( !password ? [{ field: "password", message: "请输入密码" }] : []),
      ]);
    }

    const result = mockLogin(username, password);

    if (!result) {
      return errorResponse("UNAUTHORIZED", "用户名或密码错误");
    }

    return Response.json(success({
      token: result.token,
      user: result.user,
    }));
  } catch {
    return errorResponse("INTERNAL_ERROR", "服务器错误");
  }
}
