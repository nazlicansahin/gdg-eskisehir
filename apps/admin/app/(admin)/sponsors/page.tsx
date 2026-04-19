import SubmitButton from "@/app/components/submit-button";
import {
  createSponsor2,
  deleteSponsor,
  isAuthError,
  listAdminEvents,
  listSponsors,
  toFriendlyMessage,
} from "@/lib/api";
import { clearAuthTokenCookie, getAuthTokenFromCookie } from "@/lib/auth";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

const tiers = ["platinum", "gold", "silver", "partner"] as const;

type Props = {
  searchParams?: {
    message?: string;
    kind?: string;
    filter?: "all" | "general" | string;
  };
};

export default async function SponsorsPage({ searchParams }: Props) {
  const token = await getAuthTokenFromCookie();
  if (!token) {
    redirect("/login");
  }

  async function addSponsor(formData: FormData) {
    "use server";
    const authToken = await getAuthTokenFromCookie();
    if (!authToken) {
      redirect("/login");
    }
    const name = String(formData.get("name") ?? "").trim();
    const tier = String(formData.get("tier") ?? "partner").trim();
    const logoUrl = String(formData.get("logoUrl") ?? "").trim() || undefined;
    const websiteUrl =
      String(formData.get("websiteUrl") ?? "").trim() || undefined;
    const eventId =
      String(formData.get("eventId") ?? "").trim() || undefined;
    if (!name) {
      redirect("/sponsors?kind=error&message=Name+is+required");
    }
    let kind = "success";
    let message = `Sponsor "${name}" added`;
    try {
      await createSponsor2(authToken, {
        eventId: eventId === "__general__" ? undefined : eventId,
        name,
        logoUrl,
        websiteUrl,
        tier,
      });
    } catch (error) {
      if (isAuthError(error)) {
        await clearAuthTokenCookie();
        redirect("/login");
      }
      kind = "error";
      message = toFriendlyMessage(error, "Failed to create sponsor");
    }
    revalidatePath("/sponsors");
    redirect(`/sponsors?kind=${kind}&message=${encodeURIComponent(message)}`);
  }

  async function removeSponsor(formData: FormData) {
    "use server";
    const authToken = await getAuthTokenFromCookie();
    if (!authToken) {
      redirect("/login");
    }
    const sponsorId = String(formData.get("sponsorId") ?? "").trim();
    if (!sponsorId) return;
    let kind = "success";
    let message = "Sponsor removed";
    try {
      await deleteSponsor(authToken, sponsorId);
    } catch (error) {
      if (isAuthError(error)) {
        await clearAuthTokenCookie();
        redirect("/login");
      }
      kind = "error";
      message = toFriendlyMessage(error, "Failed to delete sponsor");
    }
    revalidatePath("/sponsors");
    redirect(`/sponsors?kind=${kind}&message=${encodeURIComponent(message)}`);
  }

  try {
    const [sponsors, events] = await Promise.all([
      listSponsors(token),
      listAdminEvents(token),
    ]);

    const notice =
      searchParams?.message === "NEXT_REDIRECT"
        ? null
        : searchParams?.message;
    const isSuccess = searchParams?.kind === "success";
    const filter = searchParams?.filter ?? "all";

    const filtered =
      filter === "all"
        ? sponsors
        : filter === "general"
          ? sponsors.filter((s) => !s.eventId)
          : sponsors.filter((s) => s.eventId === filter);

    const eventMap: Record<string, string> = {};
    for (const e of events) {
      eventMap[e.id] = e.title;
    }

    return (
      <div className="panel">
        <h1 style={{ marginTop: 0 }}>Sponsors</h1>
        <p className="muted">
          Manage event-specific and general sponsors.
        </p>
        {notice ? (
          <p className={`notice ${isSuccess ? "success" : "error"}`}>
            {notice}
          </p>
        ) : null}

        <form
          action={addSponsor}
          style={{
            display: "grid",
            gridTemplateColumns: "1fr 1fr",
            gap: 8,
            marginBottom: 16,
            padding: 16,
            border: "1px solid var(--g-outline-variant)",
            borderRadius: 12,
          }}
        >
          <div style={{ gridColumn: "1 / -1" }}>
            <strong>Add sponsor</strong>
          </div>
          <div>
            <label>Name</label>
            <input name="name" className="input" required placeholder="Google" />
          </div>
          <div>
            <label>Tier</label>
            <select name="tier" className="input" defaultValue="partner">
              {tiers.map((t) => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label>Logo URL</label>
            <input
              name="logoUrl"
              className="input"
              placeholder="https://logo.clearbit.com/google.com"
            />
          </div>
          <div>
            <label>Website URL</label>
            <input
              name="websiteUrl"
              className="input"
              placeholder="https://google.com"
            />
          </div>
          <div>
            <label>Event (or general)</label>
            <select name="eventId" className="input" defaultValue="__general__">
              <option value="__general__">General (not event-specific)</option>
              {events.map((e) => (
                <option key={e.id} value={e.id}>
                  {e.title}
                </option>
              ))}
            </select>
          </div>
          <div style={{ display: "flex", alignItems: "flex-end" }}>
            <SubmitButton
              idleLabel="Add sponsor"
              pendingLabel="Adding..."
              className="button"
            />
          </div>
        </form>

        <form
          method="GET"
          style={{ display: "flex", gap: 8, marginBottom: 12 }}
        >
          <select name="filter" className="input" defaultValue={filter}>
            <option value="all">All sponsors</option>
            <option value="general">General only</option>
            {events.map((e) => (
              <option key={e.id} value={e.id}>
                {e.title}
              </option>
            ))}
          </select>
          <button className="button secondary" type="submit">
            Filter
          </button>
        </form>

        <table className="table">
          <thead>
            <tr>
              <th>Logo</th>
              <th>Name</th>
              <th>Tier</th>
              <th>Event</th>
              <th>Website</th>
              <th>Remove</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((sponsor) => (
              <tr key={sponsor.id}>
                <td>
                  {sponsor.logoUrl ? (
                    <img
                      src={sponsor.logoUrl}
                      alt={sponsor.name}
                      style={{
                        width: 36,
                        height: 36,
                        objectFit: "contain",
                        borderRadius: 6,
                      }}
                    />
                  ) : (
                    <span className="muted">-</span>
                  )}
                </td>
                <td>{sponsor.name}</td>
                <td>
                  <span className={`badge badge-${sponsor.tier === "platinum" ? "published" : sponsor.tier === "gold" ? "draft" : "active"}`}>
                    {sponsor.tier}
                  </span>
                </td>
                <td>
                  {sponsor.eventId
                    ? eventMap[sponsor.eventId] ?? sponsor.eventId
                    : "General"}
                </td>
                <td>
                  {sponsor.websiteUrl ? (
                    <a
                      href={sponsor.websiteUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="link-button"
                    >
                      Visit
                    </a>
                  ) : (
                    "-"
                  )}
                </td>
                <td>
                  <form action={removeSponsor}>
                    <input
                      type="hidden"
                      name="sponsorId"
                      value={sponsor.id}
                    />
                    <SubmitButton
                      idleLabel="Remove"
                      pendingLabel="..."
                      className="button secondary"
                    />
                  </form>
                </td>
              </tr>
            ))}
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={6} className="muted">
                  No sponsors found for current filter.
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
        <h1 style={{ marginTop: 0 }}>Sponsors</h1>
        <p className="muted">Could not load sponsors.</p>
        <pre className="muted">
          {toFriendlyMessage(error, "Sponsors query failed")}
        </pre>
      </div>
    );
  }
}
