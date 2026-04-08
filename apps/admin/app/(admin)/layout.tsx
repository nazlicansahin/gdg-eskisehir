import { redirect } from "next/navigation";
import { clearAuthTokenCookie, getAuthTokenFromCookie } from "@/lib/auth";
import { getMe, getMyRoles, isAuthError } from "@/lib/api";
import SidebarNav from "../components/sidebar-nav";
import SubmitButton from "../components/submit-button";

export default async function AdminLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  async function logout() {
    "use server";
    await clearAuthTokenCookie();
    redirect("/login");
  }

  const token = await getAuthTokenFromCookie();
  if (!token) {
    redirect("/login");
  }

  let roles: string[];
  let email = "";
  try {
    const me = await getMe(token);
    roles = me.roles;
    email = me.email;
  } catch (error) {
    if (isAuthError(error)) {
      await clearAuthTokenCookie();
      redirect("/login");
    }
    throw error;
  }

  if (!roles.includes("organizer") && !roles.includes("super_admin")) {
    redirect("/login");
  }

  return (
    <main className="container admin-grid">
      <aside className="panel sidebar">
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontSize: 18, fontWeight: 700, letterSpacing: -0.3 }}>
            <span style={{ color: "#4285f4" }}>G</span>
            <span style={{ color: "#ea4335" }}>D</span>
            <span style={{ color: "#fbbc04" }}>G</span>
          </div>
          <span style={{ fontSize: 12, color: "#5f6368", fontWeight: 500 }}>Organizer Panel</span>
        </div>
        <SidebarNav />
        <div className="sidebar-footer">
          <p className="sidebar-email">{email}</p>
          <form action={logout}>
            <SubmitButton
              idleLabel="Log out"
              pendingLabel="Logging out..."
              className="button secondary"
            />
          </form>
        </div>
      </aside>
      <section>{children}</section>
    </main>
  );
}
