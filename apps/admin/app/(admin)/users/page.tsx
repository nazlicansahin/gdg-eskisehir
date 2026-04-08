import SubmitButton from "@/app/components/submit-button";
import {
  getMe,
  grantUserRole,
  isAuthError,
  listAdminUsers,
  revokeUserRole,
  toFriendlyMessage,
} from "@/lib/api";
import { clearAuthTokenCookie, getAuthTokenFromCookie } from "@/lib/auth";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";

const manageableRoles = ["team_member", "crew", "organizer"] as const;

type Props = {
  searchParams?: {
    message?: string;
    kind?: string;
    email?: string;
    role?: "all" | "member" | "team_member" | "crew" | "organizer" | "super_admin";
  };
};

export default async function UsersPage({ searchParams }: Props) {
  const token = await getAuthTokenFromCookie();
  if (!token) {
    redirect("/login");
  }

  async function updateRole(formData: FormData) {
    "use server";
    const authToken = await getAuthTokenFromCookie();
    if (!authToken) {
      redirect("/login");
    }

    const userId = String(formData.get("userId") ?? "");
    const role = String(formData.get("role") ?? "") as (typeof manageableRoles)[number];
    const action = String(formData.get("action") ?? "");
    if (!userId || !manageableRoles.includes(role)) {
      return;
    }
    let kind = "success";
    let message = "";
    try {
      if (action === "grant") {
        await grantUserRole(authToken, userId, role);
        message = `${role} granted`;
      } else if (action === "revoke") {
        const me = await getMe(authToken);
        // Prevent organizers from accidentally removing their own organizer role.
        if (me.id === userId && role === "organizer") {
          kind = "error";
          message = "You cannot revoke your own organizer role.";
          revalidatePath("/users");
          redirect(`/users?kind=${kind}&message=${encodeURIComponent(message)}`);
        }
        await revokeUserRole(authToken, userId, role);
        message = `${role} revoked`;
      } else {
        kind = "error";
        message = "Unknown role action";
      }
    } catch (error) {
      if (isAuthError(error)) {
        await clearAuthTokenCookie();
        redirect("/login");
      }
      kind = "error";
      message = toFriendlyMessage(error, "Role update failed");
    }
    revalidatePath("/users");
    redirect(`/users?kind=${kind}&message=${encodeURIComponent(message)}`);
  }

  try {
    const users = await listAdminUsers(token);
    const me = await getMe(token);
    const notice = searchParams?.message;
    const isSuccess = searchParams?.kind === "success";
    const emailFilter = (searchParams?.email ?? "").trim().toLowerCase();
    const roleFilter = searchParams?.role ?? "all";
    const filteredUsers = users.filter((user) => {
      const emailMatch = emailFilter ? user.email.toLowerCase().includes(emailFilter) : true;
      const roleMatch = roleFilter === "all" ? true : user.roles.includes(roleFilter);
      return emailMatch && roleMatch;
    });
    return (
      <div className="panel">
        <h1 style={{ marginTop: 0 }}>Users & Roles</h1>
        <p className="muted">Add roles from dropdown, remove roles from chip close icon.</p>
        <form method="GET" style={{ display: "flex", gap: 8, marginTop: 12, marginBottom: 12 }}>
          <input
            name="email"
            className="input"
            placeholder="Filter by email"
            defaultValue={searchParams?.email ?? ""}
          />
          <select name="role" className="input" defaultValue={roleFilter}>
            <option value="all">All roles</option>
            <option value="member">member</option>
            <option value="team_member">team_member</option>
            <option value="crew">crew</option>
            <option value="organizer">organizer</option>
            <option value="super_admin">super_admin</option>
          </select>
          <button className="button" type="submit">
            Filter
          </button>
        </form>
        {notice ? (
          <p className={`notice ${isSuccess ? "success" : "error"}`}>
            {notice}
          </p>
        ) : null}
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Roles</th>
              <th>Add role</th>
            </tr>
          </thead>
          <tbody>
            {filteredUsers.map((user) => (
              <tr key={user.id}>
                <td>{user.displayName}</td>
                <td>{user.email}</td>
                <td>
                  <div className="role-list">
                    {user.roles.map((role) => {
                      const isManagedRole = manageableRoles.includes(
                        role as (typeof manageableRoles)[number],
                      );
                      return (
                        <span key={role} className="role-chip">
                          {role}
                          {isManagedRole ? (
                            <form action={updateRole}>
                              <input type="hidden" name="userId" value={user.id} />
                              <input type="hidden" name="role" value={role} />
                              <SubmitButton
                                name="action"
                                value="revoke"
                                className="role-remove-button"
                                idleLabel="x"
                                pendingLabel="..."
                                title={
                                  me.id === user.id && role === "organizer"
                                    ? "You cannot remove your own organizer role"
                                    : `Remove ${role}`
                                }
                                disabled={me.id === user.id && role === "organizer"}
                              />
                            </form>
                          ) : null}
                        </span>
                      );
                    })}
                  </div>
                </td>
                <td>
                  {(() => {
                    const addableRoles = manageableRoles.filter(
                      (role) => !user.roles.includes(role),
                    );
                    return (
                  <form action={updateRole} style={{ display: "flex", gap: 8 }}>
                    <input type="hidden" name="userId" value={user.id} />
                    <select
                      name="role"
                      className="input"
                      defaultValue={addableRoles[0] ?? manageableRoles[0]}
                      disabled={addableRoles.length === 0}
                      title={
                        addableRoles.length === 0
                          ? "All manageable roles are already assigned"
                          : "Select role to add"
                      }
                    >
                      {manageableRoles.map((role) => (
                        <option key={role} value={role}>
                          {role}
                        </option>
                      ))}
                    </select>
                    <SubmitButton
                      name="action"
                      value="grant"
                      className="button"
                      idleLabel="Add"
                      pendingLabel="Adding..."
                      disabled={addableRoles.length === 0}
                      title={
                        addableRoles.length === 0
                          ? "All manageable roles are already assigned"
                          : "Add selected role"
                      }
                    />
                  </form>
                    );
                  })()}
                </td>
              </tr>
            ))}
            {filteredUsers.length === 0 ? (
              <tr>
                <td colSpan={4} className="muted">
                  No users found for current filters.
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
        <h1 style={{ marginTop: 0 }}>Users & Roles</h1>
        <p className="muted">Could not load users list.</p>
        <pre className="muted">{String(error)}</pre>
      </div>
    );
  }
}
