import Link from "next/link";
import { listAdminEvents } from "@/lib/api";
import { getAuthTokenFromCookie } from "@/lib/auth";
import { redirect } from "next/navigation";

export default async function EventsPage() {
  const token = await getAuthTokenFromCookie();
  if (!token) {
    redirect("/login");
  }

  try {
    const events = await listAdminEvents(token);
    return (
      <div className="panel">
        <h1 style={{ marginTop: 0 }}>Events</h1>
        <p className="muted">Published, draft, and cancelled events.</p>
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
            {events.map((event) => (
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
          </tbody>
        </table>
      </div>
    );
  } catch (error) {
    return (
      <div className="panel">
        <h1 style={{ marginTop: 0 }}>Events</h1>
        <p className="muted">
          Could not load events. Check `NEXT_PUBLIC_GRAPHQL_URL` and auth token flow.
        </p>
        <pre className="muted">{String(error)}</pre>
      </div>
    );
  }
}
