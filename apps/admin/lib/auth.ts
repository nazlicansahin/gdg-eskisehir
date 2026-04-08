import { cookies } from "next/headers";
import { ADMIN_TOKEN_COOKIE } from "./auth-cookie";

export async function getAuthTokenFromCookie(): Promise<string | null> {
  const cookieStore = await cookies();
  return cookieStore.get(ADMIN_TOKEN_COOKIE)?.value ?? null;
}

export async function clearAuthTokenCookie(): Promise<void> {
  const cookieStore = await cookies();
  cookieStore.delete(ADMIN_TOKEN_COOKIE);
}
