import { listEventRegistrations } from "@/lib/api";
import { getAuthTokenFromCookie } from "@/lib/auth";
import { redirect } from "next/navigation";

type Props = {
  params: { id: string };
};

export default async function EventRegistrationsPage({ params }: Props) {
  const token = await getAuthTokenFromCookie();
  if (!token) {
    redirect("/login");
  }

  try {
    const registrations = await listEventRegistrations(params.id, token);
    return (
      <div className="panel">
        <h1 style={{ marginTop: 0 }}>Registrations</h1>
        <p className="muted">Event ID: {params.id}</p>
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Status</th>
              <th>Checked in</th>
            </tr>
          </thead>
          <tbody>
            {registrations.map((registration) => (
              <tr key={registration.id}>
                <td>{registration.attendeeName}</td>
                <td>{registration.attendeeEmail}</td>
                <td>{registration.status}</td>
                <td>
                  {registration.checkedInAt
                    ? new Date(registration.checkedInAt).toLocaleString()
                    : "No"}
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
        <h1 style={{ marginTop: 0 }}>Registrations</h1>
        <p className="muted">Could not load event registrations.</p>
        <pre className="muted">{String(error)}</pre>
      </div>
    );
  }
}
