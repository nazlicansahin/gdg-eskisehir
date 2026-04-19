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

/** True when the session/token is invalid or expired — cookie should be cleared. */
export function isAuthError(error: unknown): boolean {
  return (
    error instanceof AdminApiError && error.code === "UNAUTHENTICATED"
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
        description
        status
        capacity
        startsAt
        endsAt
      }
    }
  `;
  const data = await graphQLRequest<{ adminEvents: AdminEvent[] }>(query, {}, token);
  return data.adminEvents;
}

export async function getAdminEvent(
  token: string,
  eventId: string,
): Promise<AdminEvent | null> {
  const query = `
    query AdminEvent($id: ID!) {
      adminEvent(id: $id) {
        id
        title
        description
        status
        capacity
        startsAt
        endsAt
      }
    }
  `;
  const data = await graphQLRequest<{ adminEvent: AdminEvent | null }>(
    query,
    { id: eventId },
    token,
  );
  return data.adminEvent;
}

export async function updateEvent(
  token: string,
  input: {
    id: string;
    title?: string;
    description?: string;
    capacity?: number;
    startsAt?: string;
    endsAt?: string;
  },
): Promise<void> {
  const query = `
    mutation UpdateEvent($input: UpdateEventInput!) {
      updateEvent(input: $input) {
        id
      }
    }
  `;
  await graphQLRequest(query, { input }, token);
}

export async function publishEvent(token: string, eventId: string): Promise<void> {
  const query = `
    mutation PublishEvent($eventId: ID!) {
      publishEvent(eventId: $eventId) {
        id
      }
    }
  `;
  await graphQLRequest(query, { eventId }, token);
}

export async function cancelEvent(
  token: string,
  eventId: string,
  reason: string,
): Promise<void> {
  const query = `
    mutation CancelEvent($eventId: ID!, $reason: String!) {
      cancelEvent(eventId: $eventId, reason: $reason) {
        id
      }
    }
  `;
  await graphQLRequest(query, { eventId, reason }, token);
}

export async function listEventRegistrations(
  eventId: string,
  token: string,
): Promise<EventRegistration[]> {
  const query = `
    query AdminRegistrations($eventId: ID!) {
      adminRegistrations(eventId: $eventId) {
        id
        userId
        eventId
        qrCodeValue
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

export async function createEvent(
  token: string,
  input: {
    title: string;
    description?: string;
    capacity: number;
    startsAt: string;
    endsAt: string;
  },
): Promise<{ id: string; title: string }> {
  const query = `
    mutation CreateEvent($input: CreateEventInput!) {
      createEvent(input: $input) {
        id
        title
      }
    }
  `;
  const data = await graphQLRequest<{ createEvent: { id: string; title: string } }>(
    query,
    { input },
    token,
  );
  return data.createEvent;
}

export async function createSpeaker(
  token: string,
  input: { fullName: string; bio?: string; avatarUrl?: string },
): Promise<{ id: string }> {
  const query = `
    mutation CreateSpeaker($input: CreateSpeakerInput!) {
      createSpeaker(input: $input) {
        id
      }
    }
  `;
  const data = await graphQLRequest<{ createSpeaker: { id: string } }>(
    query,
    { input },
    token,
  );
  return data.createSpeaker;
}

export async function createSession(
  token: string,
  input: {
    eventId: string;
    title: string;
    description?: string;
    startsAt: string;
    endsAt: string;
    room?: string;
  },
): Promise<{ id: string }> {
  const query = `
    mutation CreateSession($input: CreateSessionInput!) {
      createSession(input: $input) {
        id
      }
    }
  `;
  const data = await graphQLRequest<{ createSession: { id: string } }>(
    query,
    { input },
    token,
  );
  return data.createSession;
}

export async function attachSpeakerToSession(
  token: string,
  sessionId: string,
  speakerId: string,
): Promise<void> {
  const query = `
    mutation AttachSpeakerToSession($sessionId: ID!, $speakerId: ID!) {
      attachSpeakerToSession(sessionId: $sessionId, speakerId: $speakerId) {
        id
      }
    }
  `;
  await graphQLRequest(query, { sessionId, speakerId }, token);
}

export type ScheduleSessionRow = {
  id: string;
  eventId: string;
  title: string;
  description: string | null;
  startsAt: string;
  endsAt: string;
  room: string | null;
  speakers: {
    id: string;
    fullName: string;
    bio: string | null;
    avatarUrl: string | null;
  }[];
};

export async function listEventSchedule(
  token: string,
  eventId: string,
): Promise<ScheduleSessionRow[]> {
  const query = `
    query EventSchedule($eventId: ID!) {
      eventSchedule(eventId: $eventId) {
        id
        eventId
        title
        description
        startsAt
        endsAt
        room
        speakers {
          id
          fullName
          bio
          avatarUrl
        }
      }
    }
  `;
  const data = await graphQLRequest<{ eventSchedule: ScheduleSessionRow[] }>(
    query,
    { eventId },
    token,
  );
  return data.eventSchedule ?? [];
}

export async function updateSession(
  token: string,
  input: {
    id: string;
    title?: string;
    description?: string;
    startsAt?: string;
    endsAt?: string;
    room?: string;
  },
): Promise<void> {
  const query = `
    mutation UpdateSession($input: UpdateSessionInput!) {
      updateSession(input: $input) {
        id
      }
    }
  `;
  await graphQLRequest(query, { input }, token);
}

export async function updateSpeaker(
  token: string,
  input: {
    id: string;
    fullName?: string;
    bio?: string;
    avatarUrl?: string;
  },
): Promise<void> {
  const query = `
    mutation UpdateSpeaker($input: UpdateSpeakerInput!) {
      updateSpeaker(input: $input) {
        id
      }
    }
  `;
  await graphQLRequest(query, { input }, token);
}

export type SponsorItem = {
  id: string;
  eventId: string | null;
  name: string;
  logoUrl: string | null;
  websiteUrl: string | null;
  tier: string;
};

export async function listSponsors(
  token: string,
  eventId?: string,
): Promise<SponsorItem[]> {
  const query = `
    query Sponsors($eventId: ID) {
      sponsors(eventId: $eventId) {
        id eventId name logoUrl websiteUrl tier
      }
    }
  `;
  const data = await graphQLRequest<{ sponsors: SponsorItem[] }>(
    query,
    eventId ? { eventId } : {},
    token,
  );
  return data.sponsors;
}

export async function createSponsor2(
  token: string,
  input: {
    eventId?: string;
    name: string;
    logoUrl?: string;
    websiteUrl?: string;
    tier: string;
  },
): Promise<void> {
  const query = `
    mutation CreateSponsor($input: CreateSponsorInput!) {
      createSponsor(input: $input) {
        id
      }
    }
  `;
  await graphQLRequest(query, { input }, token);
}

export async function deleteSponsor(
  token: string,
  id: string,
): Promise<void> {
  const query = `
    mutation DeleteSponsor($id: ID!) {
      deleteSponsor(id: $id)
    }
  `;
  await graphQLRequest(query, { id }, token);
}
