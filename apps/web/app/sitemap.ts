import type { MetadataRoute } from "next";
import { routing } from "@/i18n/routing";

/** Public routes per locale — keep in sync with app/[locale] routes. */
const PATHS = ["", "/privacy", "/terms", "/support"] as const;

export default function sitemap(): MetadataRoute.Sitemap {
  const base =
    process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, "") ??
    "http://localhost:3000";

  const lastModified = new Date();

  const entries: MetadataRoute.Sitemap = [];

  for (const locale of routing.locales) {
    for (const path of PATHS) {
      entries.push({
        url: `${base}/${locale}${path}`,
        lastModified,
        changeFrequency: path === "" ? "monthly" : "monthly",
        priority: path === "" ? 1 : 0.75,
      });
    }
  }

  return entries;
}
