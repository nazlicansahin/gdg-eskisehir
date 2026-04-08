import { listAdminUsers } from "@/lib/api";
import { getAuthTokenFromCookie } from "@/lib/auth";
import { redirect } from "next/navigation";

export default async function UsersPage() {
  const token = await getAuthTokenFromCookie();
  if (!token) {
    redirect("/login");
  }

  try {
    const users = await listAdminUsers(token);
    return (
      <div className="panel">
        <h1 style={{ marginTop: 0 }}>Users & Roles</h1>
        <p className="muted">
          Role grant/revoke UI will be connected to mutations in next step.
        </p>
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Roles</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id}>
                <td>{user.displayName}</td>
                <td>{user.email}</td>
                <td>{user.roles.join(", ")}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  } catch (error) {
    return (
      <div className="panel">
        <h1 style={{ marginTop: 0 }}>Users & Roles</h1>
        <p className="muted">Could not load users list.</p>
        <pre className="muted">{String(error)}</pre>
      </div>
    );
  }
}
