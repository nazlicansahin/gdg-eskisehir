export default function CheckinPage() {
  return (
    <div className="panel">
      <h1 style={{ marginTop: 0 }}>Check-in</h1>
      <p className="muted">
        Staff roles (`team_member`, `crew`, `organizer`, `super_admin`) can check in
        attendees using QR or manual registration ID.
      </p>

      <div style={{ display: "grid", gap: 12, maxWidth: 560 }}>
        <div>
          <label htmlFor="event-id">Event ID</label>
          <input id="event-id" className="input" placeholder="event-uuid" />
        </div>
        <div>
          <label htmlFor="qr">QR code value</label>
          <input id="qr" className="input" placeholder="qr-token-value" />
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          <button className="button" type="button">
            Check in by QR
          </button>
          <button className="button secondary" type="button">
            Manual check-in
          </button>
        </div>
      </div>
    </div>
  );
}
