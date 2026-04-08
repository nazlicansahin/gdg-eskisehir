import CreateEventModal from "@/app/components/create-event-modal";
import EventDetailModal from "@/app/components/event-detail-modal";
import {
  attachSpeakerToSession,
  cancelEvent,
  createEvent,
  createSession,
  createSpeaker,
  isAuthError,
  listAdminEvents,
  publishEvent,
  toFriendlyMessage,
  updateEvent,
} from "@/lib/api";
import { clearAuthTokenCookie, getAuthTokenFromCookie } from "@/lib/auth";
import { redirect } from "next/navigation";

type Props = {
  searchParams?: {
    q?: string;
    status?: "draft" | "published" | "cancelled" | "all";
    message?: string;
    kind?: "success" | "error";
  };
};

export default async function EventsPage({ searchParams }: Props) {
  async function createEventAction(formData: FormData) {
    "use server";

    const composeDescription = (
      baseDescription: string,
      extras: {
        location?: string;
        eventImageUrl?: string;
        isFree: boolean;
        price?: string;
      },
    ): string => {
      const lines = [baseDescription.trim()];
      if (extras.location?.trim()) {
        lines.push(`Location: ${extras.location.trim()}`);
      }
      lines.push(`Pricing: ${extras.isFree ? "Free" : `Paid (${extras.price || "n/a"})`}`);
      if (extras.eventImageUrl?.trim()) {
        lines.push(`Event image: ${extras.eventImageUrl.trim()}`);
      }
      return lines.filter(Boolean).join("\n\n");
    };
    const authToken = await getAuthTokenFromCookie();
    if (!authToken) {
      redirect("/login");
    }

    const title = String(formData.get("title") ?? "").trim();
    const description = String(formData.get("description") ?? "");
    const startsAtRaw = String(formData.get("startsAt") ?? "").trim();
    const endsAtRaw = String(formData.get("endsAt") ?? "").trim();
    const capacityRaw = String(formData.get("capacity") ?? "0").trim();
    const location = String(formData.get("location") ?? "");
    const eventImageUrl = String(formData.get("eventImageUrl") ?? "");
    const isFree = formData.get("isFree") === "on";
    const price = String(formData.get("price") ?? "").trim();

    if (!title || !startsAtRaw || !endsAtRaw) {
      redirect("/events?kind=error&message=Title,+startsAt,+and+endsAt+are+required");
    }

    const capacity = Number(capacityRaw);
    if (!Number.isFinite(capacity) || capacity <= 0) {
      redirect("/events?kind=error&message=Capacity+must+be+greater+than+0");
    }

    const startsAt = new Date(startsAtRaw).toISOString();
    const endsAt = new Date(endsAtRaw).toISOString();
    if (new Date(endsAt).getTime() <= new Date(startsAt).getTime()) {
      redirect("/events?kind=error&message=End+time+must+be+after+start+time");
    }

    let kind = "success";
    let message = "Event created successfully";
    try {
      const created = await createEvent(authToken, {
        title,
        description: composeDescription(description, {
          location,
          eventImageUrl,
          isFree,
          price,
        }),
        capacity,
        startsAt,
        endsAt,
      });

      const speakerNames = formData.getAll("speakerName").map((v) => String(v).trim());
      const speakerBios = formData.getAll("speakerBio").map((v) => String(v).trim());
      const speakerAvatarUrls = formData
        .getAll("speakerAvatarUrl")
        .map((v) => String(v).trim());
      const topicTitles = formData.getAll("topicTitle").map((v) => String(v).trim());
      const topicDescriptions = formData
        .getAll("topicDescription")
        .map((v) => String(v).trim());
      const topicRooms = formData.getAll("topicRoom").map((v) => String(v).trim());

      let speakerCount = 0;
      let sessionCount = 0;
      for (let i = 0; i < Math.max(speakerNames.length, topicTitles.length); i += 1) {
        const speakerName = speakerNames[i] ?? "";
        const topicTitle = topicTitles[i] ?? "";
        let speakerId = "";
        if (speakerName) {
          const speaker = await createSpeaker(authToken, {
            fullName: speakerName,
            bio: speakerBios[i] || undefined,
            avatarUrl: speakerAvatarUrls[i] || undefined,
          });
          speakerId = speaker.id;
          speakerCount += 1;
        }
        if (topicTitle) {
          const session = await createSession(authToken, {
            eventId: created.id,
            title: topicTitle,
            description: topicDescriptions[i] || undefined,
            startsAt,
            endsAt,
            room: topicRooms[i] || undefined,
          });
          sessionCount += 1;
          if (speakerId) {
            await attachSpeakerToSession(authToken, session.id, speakerId);
          }
        }
      }

      message = `Event created successfully. Sessions: ${sessionCount}, Speakers: ${speakerCount}`;
    } catch (error) {
      if (isAuthError(error)) {
        await clearAuthTokenCookie();
        redirect("/login");
      }
      if (error instanceof Error && error.message.includes("NEXT_REDIRECT")) {
        throw error;
      }
      kind = "error";
      message = toFriendlyMessage(error, "Create event failed");
    }
    redirect(`/events?kind=${kind}&message=${encodeURIComponent(message)}`);
  }

  async function updateEventAction(formData: FormData) {
    "use server";
    const authToken = await getAuthTokenFromCookie();
    if (!authToken) {
      redirect("/login");
    }
    const eventId = String(formData.get("eventId") ?? "").trim();
    const title = String(formData.get("title") ?? "").trim();
    const description = String(formData.get("description") ?? "").trim();
    const startsAtRaw = String(formData.get("startsAt") ?? "").trim();
    const endsAtRaw = String(formData.get("endsAt") ?? "").trim();
    const capacity = Number(String(formData.get("capacity") ?? "0").trim());
    const previousStatus = String(formData.get("previousStatus") ?? "").trim();
    const targetStatus = String(formData.get("targetStatus") ?? "").trim();
    const cancelReason = String(formData.get("cancelReason") ?? "").trim();
    if (!eventId || !title || !startsAtRaw || !endsAtRaw || !Number.isFinite(capacity) || capacity <= 0) {
      redirect("/events?kind=error&message=Please+fill+all+required+fields+correctly");
    }
    const startsAt = new Date(startsAtRaw).toISOString();
    const endsAt = new Date(endsAtRaw).toISOString();
    if (new Date(endsAt).getTime() <= new Date(startsAt).getTime()) {
      redirect("/events?kind=error&message=End+time+must+be+after+start+time");
    }
    let kind = "success";
    let message = "Event updated";
    try {
      await updateEvent(authToken, {
        id: eventId,
        title,
        description,
        capacity,
        startsAt,
        endsAt,
      });
      if (targetStatus !== previousStatus) {
        if (targetStatus === "published") {
          await publishEvent(authToken, eventId);
          message = "Event updated and published";
        } else if (targetStatus === "cancelled") {
          if (!cancelReason) {
            kind = "error";
            message = "Cancel reason is required for cancelled status";
          } else {
            await cancelEvent(authToken, eventId, cancelReason);
            message = "Event updated and cancelled";
          }
        } else if (targetStatus === "draft") {
          kind = "error";
          message = "Draft transition from published/cancelled is not supported";
        }
      }
    } catch (error) {
      if (isAuthError(error)) {
        await clearAuthTokenCookie();
        redirect("/login");
      }
      if (error instanceof Error && error.message.includes("NEXT_REDIRECT")) {
        throw error;
      }
      kind = "error";
      message = toFriendlyMessage(error, "Update event failed");
    }
    redirect(`/events?kind=${kind}&message=${encodeURIComponent(message)}`);
  }

  const token = await getAuthTokenFromCookie();
  if (!token) {
    redirect("/login");
  }

  try {
    const query = (searchParams?.q ?? "").trim().toLowerCase();
    const status = searchParams?.status ?? "all";
    const notice = searchParams?.message === "NEXT_REDIRECT" ? null : searchParams?.message;
    const isSuccess = searchParams?.kind === "success";
    const events = await listAdminEvents(token);
    const filtered = events.filter((event) => {
      const statusMatch = status === "all" ? true : event.status === status;
      const textMatch = query ? event.title.toLowerCase().includes(query) : true;
      return statusMatch && textMatch;
    });
    return (
      <div className="panel">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 12 }}>
          <h1 style={{ marginTop: 0, marginBottom: 0 }}>Events</h1>
          <CreateEventModal action={createEventAction} />
        </div>
        <p className="muted">Published, draft, and cancelled events.</p>
        {notice ? (
          <p className={`notice ${isSuccess ? "success" : "error"}`}>{notice}</p>
        ) : null}
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
        <EventDetailModal
          events={filtered}
          onUpdate={updateEventAction}
        />
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
