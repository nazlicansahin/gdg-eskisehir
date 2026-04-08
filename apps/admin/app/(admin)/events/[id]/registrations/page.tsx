import {
  getAdminEvent,
  isAuthError,
  listEventRegistrations,
  toFriendlyMessage,
} from "@/lib/api";
import { clearAuthTokenCookie, getAuthTokenFromCookie } from "@/lib/auth";
import { redirect } from "next/navigation";

type Props = {
  params: { id: string };
  searchParams?: {
    q?: string;
    status?: "all" | "active" | "cancelled";
    checkin?: "all" | "checked_in" | "not_checked_in";
    sort?: "status_asc" | "status_desc" | "user_asc" | "user_desc" | "checkin_first" | "not_checked_first";
  };
};

export default async function EventRegistrationsPage({ params, searchParams }: Props) {
  const token = await getAuthTokenFromCookie();
  if (!token) {
    redirect("/login");
  }

  try {
    const event = await getAdminEvent(token, params.id);
    const registrations = await listEventRegistrations(params.id, token);
    const query = (searchParams?.q ?? "").trim().toLowerCase();
    const statusFilter = searchParams?.status ?? "all";
    const checkinFilter = searchParams?.checkin ?? "all";
    const sort = searchParams?.sort ?? "checkin_first";

    const filtered = registrations.filter((registration) => {
      const textMatch = query
        ? registration.userId.toLowerCase().includes(query) ||
          registration.id.toLowerCase().includes(query)
        : true;
      const statusMatch = statusFilter === "all" ? true : registration.status === statusFilter;
      const checkinMatch =
        checkinFilter === "all"
          ? true
          : checkinFilter === "checked_in"
            ? Boolean(registration.checkedInAt)
            : !registration.checkedInAt;
      return textMatch && statusMatch && checkinMatch;
    });

    const sorted = [...filtered].sort((a, b) => {
      switch (sort) {
        case "status_asc":
          return a.status.localeCompare(b.status);
        case "status_desc":
          return b.status.localeCompare(a.status);
        case "user_asc":
          return a.userId.localeCompare(b.userId);
        case "user_desc":
          return b.userId.localeCompare(a.userId);
        case "not_checked_first":
          return Number(Boolean(a.checkedInAt)) - Number(Boolean(b.checkedInAt));
        case "checkin_first":
        default:
          return Number(Boolean(b.checkedInAt)) - Number(Boolean(a.checkedInAt));
      }
    });

    return (
      <div className="panel">
        <h1 style={{ marginTop: 0 }}>Registrations</h1>
        <p className="muted">
          Event: {event?.title ?? "Unknown event"} | Total applications: {registrations.length}
        </p>
        <form method="GET" style={{ display: "flex", gap: 8, marginBottom: 12, flexWrap: "wrap" }}>
          <input
            name="q"
            className="input"
            placeholder="Search by user or registration ID"
            defaultValue={searchParams?.q ?? ""}
          />
          <select name="status" className="input" defaultValue={statusFilter}>
            <option value="all">All status</option>
            <option value="active">active</option>
            <option value="cancelled">cancelled</option>
          </select>
          <select name="checkin" className="input" defaultValue={checkinFilter}>
            <option value="all">All check-in</option>
            <option value="checked_in">checked-in</option>
            <option value="not_checked_in">not checked-in</option>
          </select>
          <select name="sort" className="input" defaultValue={sort}>
            <option value="checkin_first">Sort: checked-in first</option>
            <option value="not_checked_first">Sort: not checked-in first</option>
            <option value="status_asc">Sort: status asc</option>
            <option value="status_desc">Sort: status desc</option>
            <option value="user_asc">Sort: user ID asc</option>
            <option value="user_desc">Sort: user ID desc</option>
          </select>
          <button className="button" type="submit">
            Apply
          </button>
        </form>
        <table className="table">
          <thead>
            <tr>
              <th>Registration ID</th>
              <th>User ID</th>
              <th>Status</th>
              <th>Check-in</th>
              <th>QR</th>
            </tr>
          </thead>
          <tbody>
            {sorted.map((registration) => (
              <tr key={registration.id}>
                <td>{registration.id}</td>
                <td>{registration.userId}</td>
                <td><span className={`badge badge-${registration.status}`}>{registration.status}</span></td>
                <td>
                  {registration.checkedInAt ? (
                    <span className="badge badge-checked">{new Date(registration.checkedInAt).toLocaleString()}</span>
                  ) : (
                    <span className="badge badge-not-checked">Not yet</span>
                  )}
                </td>
                <td>{registration.qrCodeValue}</td>
              </tr>
            ))}
            {sorted.length === 0 ? (
              <tr>
                <td colSpan={5} className="muted">
                  No registrations found for current filters.
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
        <h1 style={{ marginTop: 0 }}>Registrations</h1>
        <p className="muted">Could not load event registrations.</p>
        <pre className="muted">{toFriendlyMessage(error, "Registrations query failed")}</pre>
      </div>
    );
  }
}
