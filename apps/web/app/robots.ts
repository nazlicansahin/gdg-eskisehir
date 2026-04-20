import type { MetadataRoute } from "next";

/**
 * Crawl rules for search engines. Set NEXT_PUBLIC_SITE_URL in production so
 * sitemap and host in robots.txt match your canonical domain.
 */
export default function robots(): MetadataRoute.Robots {
  const base =
    process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, "") ??
    "http://localhost:3000";

  return {
    rules: {
      userAgent: "*",
      allow: "/",
    },
    sitemap: `${base}/sitemap.xml`,
  };
}
