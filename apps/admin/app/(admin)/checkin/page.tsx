import SubmitButton from "@/app/components/submit-button";
import {
  checkInByQR,
  isAuthError,
  manualCheckIn,
  toFriendlyMessage,
} from "@/lib/api";
import { clearAuthTokenCookie, getAuthTokenFromCookie } from "@/lib/auth";
import { redirect } from "next/navigation";

type Props = {
  searchParams?: {
    message?: string;
    kind?: string;
  };
};

export default async function CheckinPage({ searchParams }: Props) {
  const token = await getAuthTokenFromCookie();
  if (!token) {
    redirect("/login");
  }

  async function submitQrCheckIn(formData: FormData) {
    "use server";
    const authToken = await getAuthTokenFromCookie();
    if (!authToken) {
      redirect("/login");
    }
    const eventId = String(formData.get("eventId") ?? "").trim();
    const qrCode = String(formData.get("qrCode") ?? "").trim();
    if (!eventId || !qrCode) {
      redirect("/checkin?kind=error&message=Event+ID+and+QR+code+are+required");
    }
    try {
      const result = await checkInByQR(authToken, eventId, qrCode);
      redirect(
        `/checkin?kind=success&message=QR+check-in+completed+for+registration+${result.id}`,
      );
    } catch (error) {
      if (isAuthError(error)) {
        await clearAuthTokenCookie();
        redirect("/login");
      }
      const message = toFriendlyMessage(error, "QR check-in failed");
      redirect(`/checkin?kind=error&message=${encodeURIComponent(message)}`);
    }
  }

  async function submitManualCheckIn(formData: FormData) {
    "use server";
    const authToken = await getAuthTokenFromCookie();
    if (!authToken) {
      redirect("/login");
    }
    const registrationId = String(formData.get("registrationId") ?? "").trim();
    if (!registrationId) {
      redirect("/checkin?kind=error&message=Registration+ID+is+required");
    }
    try {
      const result = await manualCheckIn(authToken, registrationId);
      redirect(
        `/checkin?kind=success&message=Manual+check-in+completed+for+registration+${result.id}`,
      );
    } catch (error) {
      if (isAuthError(error)) {
        await clearAuthTokenCookie();
        redirect("/login");
      }
      const message = toFriendlyMessage(error, "Manual check-in failed");
      redirect(`/checkin?kind=error&message=${encodeURIComponent(message)}`);
    }
  }

  const notice = searchParams?.message;
  const isSuccess = searchParams?.kind === "success";

  return (
    <div className="panel">
      <h1 style={{ marginTop: 0 }}>Check-in</h1>
      <p className="muted">
        Staff roles (`team_member`, `crew`, `organizer`, `super_admin`) can check in
        attendees using QR or manual registration ID.
      </p>
      {notice ? (
        <p className={`notice ${isSuccess ? "success" : "error"}`}>
          {notice}
        </p>
      ) : null}

      <div style={{ display: "grid", gap: 16, maxWidth: 560 }}>
        <form action={submitQrCheckIn} className="panel">
          <h3 style={{ marginTop: 0 }}>Check in by QR</h3>
          <div>
            <label htmlFor="event-id">Event ID</label>
            <input
              id="event-id"
              name="eventId"
              className="input"
              placeholder="event-uuid"
              required
            />
          </div>
          <div>
            <label htmlFor="qr">QR code value</label>
            <input
              id="qr"
              name="qrCode"
              className="input"
              placeholder="qr-token-value"
              required
            />
          </div>
          <div style={{ marginTop: 12 }}>
            <SubmitButton
              className="button"
              idleLabel="Check in by QR"
              pendingLabel="Checking in..."
            />
          </div>
        </form>

        <form action={submitManualCheckIn} className="panel">
          <h3 style={{ marginTop: 0 }}>Manual check-in</h3>
          <div>
            <label htmlFor="registration-id">Registration ID</label>
            <input
              id="registration-id"
              name="registrationId"
              className="input"
              placeholder="registration-uuid"
              required
            />
          </div>
          <div style={{ marginTop: 12 }}>
            <SubmitButton
              className="button secondary"
              idleLabel="Manual check-in"
              pendingLabel="Checking in..."
            />
          </div>
        </form>
      </div>
    </div>
  );
}
