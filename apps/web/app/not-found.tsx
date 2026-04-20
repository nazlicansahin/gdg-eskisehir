import Link from "next/link";

export default function GlobalNotFound() {
  return (
    <html lang="en">
      <body style={{ fontFamily: "system-ui", padding: "2rem", background: "#0b0f14", color: "#e8edf4" }}>
        <h1 style={{ marginTop: 0 }}>Page not found</h1>
        <p style={{ color: "#9aa7b8" }}>
          The page you requested does not exist.
        </p>
        <Link href="/en" style={{ color: "#4285f4" }}>
          Go to English home
        </Link>
      </body>
    </html>
  );
}
