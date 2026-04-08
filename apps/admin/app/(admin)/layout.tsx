import Link from "next/link";
import { redirect } from "next/navigation";
import { getAuthTokenFromCookie } from "@/lib/auth";
import { getMyRoles } from "@/lib/api";

const links = [
  { href: "/events", label: "Events" },
  { href: "/checkin", label: "Check-in" },
  { href: "/users", label: "Users & Roles" },
];

export default async function AdminLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const token = await getAuthTokenFromCookie();
  if (!token) {
    redirect("/login");
  }

  const roles = await getMyRoles(token);
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
      </aside>
      <section>{children}</section>
    </main>
  );
}
