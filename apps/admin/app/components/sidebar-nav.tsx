"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const links = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/events", label: "Events" },
  { href: "/checkin", label: "Check-in" },
  { href: "/users", label: "Users & Roles" },
];

export default function SidebarNav() {
  const pathname = usePathname();

  return (
    <nav style={{ display: "grid", gap: 4 }}>
      {links.map((link) => {
        const active = pathname === link.href || pathname.startsWith(`${link.href}/`);
        return (
          <Link
            key={link.href}
            href={link.href}
            className={`nav-link ${active ? "nav-link-active" : ""}`}
          >
            {link.label}
          </Link>
        );
      })}
    </nav>
  );
}
