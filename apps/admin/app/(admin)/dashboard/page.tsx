import { listAdminEvents, listAdminUsers, isAuthError, toFriendlyMessage } from "@/lib/api";
import { clearAuthTokenCookie, getAuthTokenFromCookie } from "@/lib/auth";
import { redirect } from "next/navigation";
import Link from "next/link";

export default async function DashboardPage() {
  const token = await getAuthTokenFromCookie();
  if (!token) {
    redirect("/login");
  }

  try {
    const [events, users] = await Promise.all([
      listAdminEvents(token),
      listAdminUsers(token),
    ]);

    const draftCount = events.filter((e) => e.status === "draft").length;
    const publishedCount = events.filter((e) => e.status === "published").length;
    const cancelledCount = events.filter((e) => e.status === "cancelled").length;
    const organizerCount = users.filter((u) => u.roles.includes("organizer")).length;
    const upcomingEvents = events
      .filter((e) => e.status === "published" && new Date(e.startsAt) > new Date())
      .sort((a, b) => new Date(a.startsAt).getTime() - new Date(b.startsAt).getTime())
      .slice(0, 5);

    return (
      <div style={{ display: "grid", gap: 16 }}>
        <h1 style={{ marginTop: 0 }}>Dashboard</h1>

        <div className="stat-grid">
          <div className="stat-card">
            <div className="stat-value">{events.length}</div>
            <div className="stat-label">Total Events</div>
          </div>
          <div className="stat-card">
            <div className="stat-value">{publishedCount}</div>
            <div className="stat-label">Published</div>
          </div>
          <div className="stat-card">
            <div className="stat-value">{draftCount}</div>
            <div className="stat-label">Drafts</div>
          </div>
          <div className="stat-card">
            <div className="stat-value">{cancelledCount}</div>
            <div className="stat-label">Cancelled</div>
          </div>
          <div className="stat-card">
            <div className="stat-value">{users.length}</div>
            <div className="stat-label">Users</div>
          </div>
          <div className="stat-card">
            <div className="stat-value">{organizerCount}</div>
            <div className="stat-label">Organizers</div>
          </div>
        </div>

        <div className="panel">
          <h3 style={{ marginTop: 0 }}>Upcoming events</h3>
          {upcomingEvents.length === 0 ? (
            <p className="muted">No upcoming published events.</p>
          ) : (
            <table className="table">
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Starts</th>
                  <th>Capacity</th>
                </tr>
              </thead>
              <tbody>
                {upcomingEvents.map((event) => (
                  <tr key={event.id}>
                    <td>
                      <Link href="/events" className="link-button">
                        {event.title}
                      </Link>
                    </td>
                    <td>{new Date(event.startsAt).toLocaleString()}</td>
                    <td>{event.capacity}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    );
  } catch (error) {
    if (isAuthError(error)) {
      await clearAuthTokenCookie();
      redirect("/login");
    }
    return (
      <div className="panel">
        <h1 style={{ marginTop: 0 }}>Dashboard</h1>
        <p className="muted">{toFriendlyMessage(error, "Could not load dashboard data")}</p>
      </div>
    );
  }
}
