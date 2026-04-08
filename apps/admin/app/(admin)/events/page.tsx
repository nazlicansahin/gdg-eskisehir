import Link from "next/link";
import { isAuthError, listAdminEvents, toFriendlyMessage } from "@/lib/api";
import { clearAuthTokenCookie, getAuthTokenFromCookie } from "@/lib/auth";
import { redirect } from "next/navigation";

type Props = {
  searchParams?: {
    q?: string;
    status?: "draft" | "published" | "cancelled" | "all";
  };
};

export default async function EventsPage({ searchParams }: Props) {
  const token = await getAuthTokenFromCookie();
  if (!token) {
    redirect("/login");
  }

  try {
    const query = (searchParams?.q ?? "").trim().toLowerCase();
    const status = searchParams?.status ?? "all";
    const events = await listAdminEvents(token);
    const filtered = events.filter((event) => {
      const statusMatch = status === "all" ? true : event.status === status;
      const textMatch = query ? event.title.toLowerCase().includes(query) : true;
      return statusMatch && textMatch;
    });
    return (
      <div className="panel">
        <h1 style={{ marginTop: 0 }}>Events</h1>
        <p className="muted">Published, draft, and cancelled events.</p>
        <form method="GET" style={{ display: "flex", gap: 8, marginBottom: 12 }}>
          <input
            name="q"
            className="input"
            placeholder="Search by title"
            defaultValue={searchParams?.q ?? ""}
          />
          <select name="status" className="input" defaultValue={status}>
            <option value="all">All statuses</option>
            <option value="draft">Draft</option>
            <option value="published">Published</option>
            <option value="cancelled">Cancelled</option>
          </select>
          <button className="button" type="submit">
            Filter
          </button>
        </form>
        <table className="table">
          <thead>
            <tr>
              <th>Title</th>
              <th>Status</th>
              <th>Starts</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((event) => (
              <tr key={event.id}>
                <td>{event.title}</td>
                <td>{event.status}</td>
                <td>{new Date(event.startsAt).toLocaleString()}</td>
                <td>
                  <Link href={`/events/${event.id}/registrations`} className="muted">
                    View registrations
                  </Link>
                </td>
              </tr>
            ))}
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={4} className="muted">
                  No events found for current filter.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    );
  } catch (error) {
    if (isAuthError(error)) {
      await clearAuthTokenCookie();
      redirect("/login");
    }
    return (
      <div className="panel">
        <h1 style={{ marginTop: 0 }}>Events</h1>
        <p className="muted">
          Could not load events. Check `NEXT_PUBLIC_GRAPHQL_URL` and auth token flow.
        </p>
        <pre className="muted">{toFriendlyMessage(error, "Events query failed")}</pre>
      </div>
    );
  }
}
