import type { AdminEvent, AdminUser, EventRegistration } from "./types";

const GRAPHQL_URL =
  process.env.NEXT_PUBLIC_GRAPHQL_URL ?? "http://localhost:8081/graphql";

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
    throw new Error(`GraphQL request failed (${res.status})`);
  }

  const json = (await res.json()) as {
    data?: TData;
    errors?: Array<{ message: string }>;
  };

  if (json.errors?.length) {
    throw new Error(json.errors[0]?.message ?? "Unknown GraphQL error");
  }

  if (!json.data) {
    throw new Error("Missing GraphQL data");
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
