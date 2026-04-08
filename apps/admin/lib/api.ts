import type { AdminEvent, AdminUser, EventRegistration } from "./types";

const GRAPHQL_URL =
  process.env.NEXT_PUBLIC_GRAPHQL_URL ?? "http://localhost:8081/graphql";

type GraphQLErrorItem = {
  message?: string;
  extensions?: { code?: string };
};

export class AdminApiError extends Error {
  code?: string;

  constructor(message: string, code?: string) {
    super(message);
    this.name = "AdminApiError";
    this.code = code;
  }
}

export function isAuthError(error: unknown): boolean {
  return (
    error instanceof AdminApiError &&
    (error.code === "UNAUTHENTICATED" || error.code === "FORBIDDEN")
  );
}

export function toFriendlyMessage(error: unknown, fallback: string): string {
  if (!(error instanceof AdminApiError)) {
    return error instanceof Error ? error.message : fallback;
  }
  switch (error.code) {
    case "INVALID_QR_CODE":
      return "QR code is invalid or does not belong to this event.";
    case "REGISTRATION_CANCELLED":
      return "This registration is cancelled and cannot be checked in.";
    case "FORBIDDEN":
      return "You do not have permission for this action.";
    case "UNAUTHENTICATED":
      return "Your session has expired. Please log in again.";
    case "NOT_FOUND":
      return "Requested record was not found.";
    default:
      return error.message || fallback;
  }
}

async function graphQLRequest<TData>(
  query: string,
  variables: Record<string, unknown> = {},
  token?: string,
): Promise<TData> {
  const res = await fetch(GRAPHQL_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({ query, variables }),
    cache: "no-store",
  });

  if (!res.ok) {
    throw new AdminApiError(`GraphQL request failed (${res.status})`);
  }

  const json = (await res.json()) as {
    data?: TData;
    errors?: GraphQLErrorItem[];
  };

  if (json.errors?.length) {
    const first = json.errors[0];
    throw new AdminApiError(
      first?.message ?? "Unknown GraphQL error",
      first?.extensions?.code,
    );
  }

  if (!json.data) {
    throw new AdminApiError("Missing GraphQL data");
  }

  return json.data;
}

export async function listAdminEvents(token: string): Promise<AdminEvent[]> {
  const query = `
    query AdminEvents {
      adminEvents {
        id
        title
        status
        startsAt
      }
    }
  `;
  const data = await graphQLRequest<{ adminEvents: AdminEvent[] }>(query, {}, token);
  return data.adminEvents;
}

export async function listEventRegistrations(
  eventId: string,
  token: string,
): Promise<EventRegistration[]> {
  const query = `
    query AdminRegistrations($eventId: ID!) {
      adminRegistrations(eventId: $eventId) {
        id
        attendeeName
        attendeeEmail
        status
        checkedInAt
      }
    }
  `;
  const data = await graphQLRequest<{ adminRegistrations: EventRegistration[] }>(
    query,
    { eventId },
    token,
  );
  return data.adminRegistrations;
}

export async function listAdminUsers(token: string): Promise<AdminUser[]> {
  const query = `
    query AdminUsers {
      adminUsers {
        id
        displayName
        email
        roles
      }
    }
  `;
  const data = await graphQLRequest<{ adminUsers: AdminUser[] }>(query, {}, token);
  return data.adminUsers;
}

export async function getMyRoles(token: string): Promise<string[]> {
  const query = `
    query MeRoles {
      me {
        roles
      }
    }
  `;
  const data = await graphQLRequest<{ me: { roles: string[] } }>(query, {}, token);
  return data.me.roles ?? [];
}

export async function getMe(
  token: string,
): Promise<{ id: string; roles: string[]; email: string }> {
  const query = `
    query MeSummary {
      me {
        id
        email
        roles
      }
    }
  `;
  const data = await graphQLRequest<{
    me: { id: string; email: string; roles: string[] };
  }>(query, {}, token);
  return data.me;
}

export async function grantUserRole(
  token: string,
  userId: string,
  role: "team_member" | "crew" | "organizer" | "super_admin",
): Promise<void> {
  const query = `
    mutation GrantUserRole($userId: ID!, $role: Role!) {
      grantUserRole(userId: $userId, role: $role) {
        id
      }
    }
  `;
  await graphQLRequest(query, { userId, role }, token);
}

export async function revokeUserRole(
  token: string,
  userId: string,
  role: "team_member" | "crew" | "organizer" | "super_admin",
): Promise<void> {
  const query = `
    mutation RevokeUserRole($userId: ID!, $role: Role!) {
      revokeUserRole(userId: $userId, role: $role) {
        id
      }
    }
  `;
  await graphQLRequest(query, { userId, role }, token);
}

export async function checkInByQR(
  token: string,
  eventId: string,
  qrCode: string,
): Promise<{ id: string; checkedInAt: string | null }> {
  const query = `
    mutation CheckInByQR($eventId: ID!, $qrCode: String!) {
      checkInByQR(eventId: $eventId, qrCode: $qrCode) {
        id
        checkedInAt
      }
    }
  `;
  const data = await graphQLRequest<{
    checkInByQR: { id: string; checkedInAt: string | null };
  }>(query, { eventId, qrCode }, token);
  return data.checkInByQR;
}

export async function manualCheckIn(
  token: string,
  registrationId: string,
): Promise<{ id: string; checkedInAt: string | null }> {
  const query = `
    mutation ManualCheckIn($registrationId: ID!) {
      manualCheckIn(registrationId: $registrationId) {
        id
        checkedInAt
      }
    }
  `;
  const data = await graphQLRequest<{
    manualCheckIn: { id: string; checkedInAt: string | null };
  }>(query, { registrationId }, token);
  return data.manualCheckIn;
}
