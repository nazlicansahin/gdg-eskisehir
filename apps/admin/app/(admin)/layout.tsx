import Link from "next/link";
import { redirect } from "next/navigation";
import { clearAuthTokenCookie, getAuthTokenFromCookie } from "@/lib/auth";
import { getMyRoles, isAuthError } from "@/lib/api";
import SubmitButton from "../components/submit-button";

const links = [
  { href: "/events", label: "Events" },
  { href: "/checkin", label: "Check-in" },
  { href: "/users", label: "Users & Roles" },
];

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
  try {
    roles = await getMyRoles(token);
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
    <main className="container" style={{ display: "grid", gridTemplateColumns: "240px 1fr", gap: 16 }}>
      <aside className="panel" style={{ height: "fit-content" }}>
        <h3 style={{ marginTop: 0 }}>Organizer Panel</h3>
        <nav style={{ display: "grid", gap: 8 }}>
          {links.map((link) => (
            <Link key={link.href} href={link.href} className="muted">
              {link.label}
            </Link>
          ))}
        </nav>
        <form action={logout} style={{ marginTop: 16 }}>
          <SubmitButton
            idleLabel="Log out"
            pendingLabel="Logging out..."
            className="button secondary"
          />
        </form>
      </aside>
      <section>{children}</section>
    </main>
  );
}
