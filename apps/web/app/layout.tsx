import "./globals.css";
import type { ReactNode } from "react";

/**
 * Root layout is required by Next.js. Locale-specific `lang`, providers, and UI
 * chrome live under `app/[locale]/layout.tsx` (next-intl pattern).
 */
export default function RootLayout({ children }: { children: ReactNode }) {
  return children;
}
