"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { signInWithEmailAndPassword } from "firebase/auth";
import { getFirebaseAuth } from "@/lib/firebase";
import { ADMIN_TOKEN_COOKIE } from "@/lib/auth-cookie";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      const auth = getFirebaseAuth();
      const credential = await signInWithEmailAndPassword(auth, email, password);
      const token = await credential.user.getIdToken();
      document.cookie = `${ADMIN_TOKEN_COOKIE}=${token}; Path=/; Max-Age=3600; SameSite=Lax`;
      router.push("/dashboard");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="container" style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center" }}>
      <section className="panel" style={{ maxWidth: 420, width: "100%" }}>
        <div style={{ textAlign: "center", marginBottom: 28 }}>
          <div style={{ fontSize: 36, fontWeight: 700, letterSpacing: -0.5 }}>
            <span style={{ color: "#4285f4" }}>G</span>
            <span style={{ color: "#ea4335" }}>D</span>
            <span style={{ color: "#fbbc04" }}>G</span>
            <span style={{ color: "#4285f4" }}> E</span>
            <span style={{ color: "#34a853" }}>s</span>
            <span style={{ color: "#ea4335" }}>k</span>
            <span style={{ color: "#4285f4" }}>i</span>
            <span style={{ color: "#fbbc04" }}>s</span>
            <span style={{ color: "#34a853" }}>e</span>
            <span style={{ color: "#ea4335" }}>h</span>
            <span style={{ color: "#4285f4" }}>i</span>
            <span style={{ color: "#fbbc04" }}>r</span>
          </div>
          <p className="muted" style={{ marginTop: 8 }}>Organizer Panel</p>
        </div>
        <form onSubmit={onSubmit}>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            className="input"
            placeholder="organizer@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            autoComplete="email"
          />
          <label htmlFor="password" style={{ marginTop: 12, display: "block" }}>
            Password
          </label>
          <input
            id="password"
            className="input"
            type="password"
            placeholder="********"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="current-password"
          />
          {error ? (
            <p className="notice error" role="alert">{error}</p>
          ) : null}
          <button
            type="submit"
            className="button"
            disabled={submitting}
            style={{ width: "100%", marginTop: 16 }}
          >
            {submitting ? "Signing in..." : "Sign in"}
          </button>
        </form>
      </section>
    </main>
  );
}
