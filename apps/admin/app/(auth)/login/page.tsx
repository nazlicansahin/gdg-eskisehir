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
      router.push("/events");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="container">
      <section className="panel" style={{ maxWidth: 480, margin: "80px auto" }}>
        <h1>Organizer Login</h1>
        <p className="muted">Sign in with Firebase, then open organizer screens.</p>
        <form onSubmit={onSubmit}>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            className="input"
            placeholder="organizer@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
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
          />
          {error ? (
            <p style={{ color: "#b91c1c", marginTop: 10 }} role="alert">
              {error}
            </p>
          ) : null}
          <div style={{ marginTop: 16, display: "flex", gap: 12 }}>
            <button type="submit" className="button" disabled={submitting}>
              {submitting ? "Signing in..." : "Sign in"}
            </button>
          </div>
        </form>
      </section>
    </main>
  );
}
