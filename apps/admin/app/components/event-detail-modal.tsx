"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import type { AdminEvent } from "@/lib/types";
import type { ScheduleSessionRow } from "@/lib/api";
import { parseEventDescription } from "@/lib/event-description";
import SubmitButton from "./submit-button";

type Props = {
  events: AdminEvent[];
  onUpdate: (formData: FormData) => Promise<void>;
  onLoadSchedule: (eventId: string) => Promise<ScheduleSessionRow[]>;
};

function toDateTimeLocal(iso: string): string {
  const date = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(
    date.getHours(),
  )}:${pad(date.getMinutes())}`;
}

function heroImageUrl(description: string | null | undefined): string | null {
  const parsed = parseEventDescription(description ?? "");
  if (parsed.eventImageUrl.trim()) {
    return parsed.eventImageUrl.trim();
  }
  const urls = (description ?? "").match(/https?:\/\/[^\s)]+/g) ?? [];
  const found = urls.find((url) => /\.(png|jpe?g|gif|webp|avif|svg)$/i.test(url));
  return found ?? null;
}

type EditRow =
  | (ScheduleSessionRow & { isNew?: false })
  | {
      id: "new";
      eventId: string;
      title: string;
      description: string | null;
      startsAt: string;
      endsAt: string;
      room: string | null;
      speakers: ScheduleSessionRow["speakers"];
      isNew: true;
    };

export default function EventDetailModal({ events, onUpdate, onLoadSchedule }: Props) {
  const [selected, setSelected] = useState<AdminEvent | null>(null);
  const [editMode, setEditMode] = useState(false);
  const [targetStatus, setTargetStatus] = useState<AdminEvent["status"]>("draft");
  const [scheduleRows, setScheduleRows] = useState<EditRow[]>([]);
  const [scheduleLoading, setScheduleLoading] = useState(false);
  const [extraNewSlots, setExtraNewSlots] = useState(0);

  const openDetails = (event: AdminEvent) => {
    setSelected(event);
    setEditMode(false);
    setTargetStatus(event.status);
    setScheduleRows([]);
    setExtraNewSlots(0);
  };

  useEffect(() => {
    if (!editMode || !selected) {
      return;
    }
    let cancelled = false;
    setScheduleLoading(true);
    void (async () => {
      try {
        const rows = await onLoadSchedule(selected.id);
        if (!cancelled) {
          setScheduleRows(rows.map((r) => ({ ...r, isNew: false as const })));
        }
      } catch {
        if (!cancelled) {
          setScheduleRows([]);
        }
      } finally {
        if (!cancelled) {
          setScheduleLoading(false);
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [editMode, selected?.id, onLoadSchedule]);

  const discardEdit = () => {
    setEditMode(false);
    setScheduleRows([]);
    setExtraNewSlots(0);
  };

  const parsedView = selected ? parseEventDescription(selected.description ?? "") : null;
  const cover = selected ? heroImageUrl(selected.description) : null;

  return (
    <>
      <table className="table">
        <thead>
          <tr>
            <th>Title</th>
            <th>Status</th>
            <th>Starts</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {events.map((event) => (
            <tr key={event.id}>
              <td>
                <button type="button" className="link-button" onClick={() => openDetails(event)}>
                  {event.title}
                </button>
              </td>
              <td>
                <span className={`badge badge-${event.status}`}>{event.status}</span>
              </td>
              <td>{new Date(event.startsAt).toLocaleString()}</td>
              <td>
                <Link href={`/events/${event.id}/registrations`} className="muted">
                  View registrations
                </Link>
              </td>
            </tr>
          ))}
          {events.length === 0 ? (
            <tr>
              <td colSpan={4} className="muted">
                No events found for current filter.
              </td>
            </tr>
          ) : null}
        </tbody>
      </table>

      {selected ? (
        <div className="modal-overlay" role="dialog" aria-modal="true" aria-label="Event details">
          <div className="modal-card panel" style={{ maxWidth: 720, maxHeight: "90vh", overflow: "auto" }}>
            <div className="modal-header">
              <div>
                <h2 style={{ margin: 0 }}>{selected.title}</h2>
                <p style={{ marginTop: 6 }}>
                  <span className={`badge badge-${selected.status}`}>{selected.status}</span>
                </p>
              </div>
              <button
                type="button"
                className="button secondary"
                onClick={() => {
                  setSelected(null);
                  discardEdit();
                }}
              >
                Close
              </button>
            </div>

            {!editMode ? (
              <div style={{ display: "grid", gap: 0 }}>
                <div
                  style={{
                    position: "relative",
                    borderRadius: 12,
                    overflow: "hidden",
                    minHeight: cover ? 200 : 140,
                    background: "linear-gradient(135deg, #1a73e8 0%, #4285f4 100%)",
                  }}
                >
                  {cover ? (
                    <img
                      src={cover}
                      alt=""
                      style={{ width: "100%", height: 220, objectFit: "cover", display: "block" }}
                    />
                  ) : null}
                  <div
                    style={{
                      position: cover ? "absolute" : "relative",
                      left: 0,
                      right: 0,
                      bottom: 0,
                      padding: 16,
                      background: cover
                        ? "linear-gradient(transparent, rgba(0,0,0,0.75))"
                        : "transparent",
                    }}
                  >
                    <h3
                      style={{
                        margin: 0,
                        color: cover ? "#fff" : "#fff",
                        fontSize: 22,
                        fontWeight: 700,
                        textShadow: cover ? "0 1px 4px rgba(0,0,0,0.5)" : undefined,
                      }}
                    >
                      {selected.title}
                    </h3>
                  </div>
                </div>

                <div
                  className="panel"
                  style={{
                    marginTop: 12,
                    padding: 16,
                    borderRadius: 12,
                    boxShadow: "0 1px 3px rgba(60,64,67,0.12)",
                  }}
                >
                  <div style={{ fontWeight: 600, fontSize: 17, marginBottom: 10 }}>{selected.title}</div>
                  <div className="muted" style={{ marginBottom: 6 }}>
                    <strong>Starts:</strong> {new Date(selected.startsAt).toLocaleString()}
                  </div>
                  <div className="muted" style={{ marginBottom: 6 }}>
                    <strong>Ends:</strong> {new Date(selected.endsAt).toLocaleString()}
                  </div>
                  <div className="muted" style={{ marginBottom: parsedView?.location ? 6 : 0 }}>
                    <strong>Capacity:</strong> {selected.capacity}
                  </div>
                  {parsedView?.location ? (
                    <div className="muted" style={{ marginBottom: 6 }}>
                      <strong>Location:</strong> {parsedView.location}
                    </div>
                  ) : null}
                  {parsedView ? (
                    <div className="muted">
                      <strong>Pricing:</strong>{" "}
                      {parsedView.isFree ? "Free" : `Paid (${parsedView.price || "n/a"})`}
                    </div>
                  ) : null}
                </div>

                {parsedView?.body ? (
                  <div style={{ marginTop: 14 }}>
                    <strong>About</strong>
                    <p className="muted" style={{ whiteSpace: "pre-wrap", marginTop: 8 }}>
                      {parsedView.body}
                    </p>
                  </div>
                ) : (
                  <p className="muted" style={{ marginTop: 14 }}>
                    No description text.
                  </p>
                )}

                <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginTop: 16 }}>
                  <button
                    type="button"
                    className="button"
                    onClick={() => {
                      setTargetStatus(selected.status);
                      setEditMode(true);
                    }}
                  >
                    Edit
                  </button>
                </div>
              </div>
            ) : (
              <form
                action={onUpdate}
                style={{ display: "grid", gap: 12 }}
                onSubmit={() => {
                  setSelected(null);
                  setEditMode(false);
                  setScheduleRows([]);
                  setExtraNewSlots(0);
                }}
              >
                <input type="hidden" name="eventId" value={selected.id} />
                <input type="hidden" name="previousStatus" value={selected.status} />

                <h3 style={{ margin: "8px 0 0", fontSize: 16 }}>Basics</h3>
                <label htmlFor="edit-title">Title</label>
                <input id="edit-title" name="title" className="input" defaultValue={selected.title} required />

                <label htmlFor="edit-body">Description (text only)</label>
                <textarea
                  id="edit-body"
                  name="bodyDescription"
                  className="input"
                  defaultValue={parseEventDescription(selected.description ?? "").body}
                  rows={4}
                />

                <label htmlFor="edit-location">Address / location</label>
                <input
                  id="edit-location"
                  name="location"
                  className="input"
                  defaultValue={parseEventDescription(selected.description ?? "").location}
                />

                <label htmlFor="edit-event-image">Event photo URL</label>
                <input
                  id="edit-event-image"
                  name="eventImageUrl"
                  className="input"
                  defaultValue={parseEventDescription(selected.description ?? "").eventImageUrl}
                  placeholder="https://..."
                />

                <label htmlFor="edit-free" style={{ display: "inline-flex", gap: 8, alignItems: "center" }}>
                  <input
                    id="edit-free"
                    name="isFree"
                    type="checkbox"
                    defaultChecked={parseEventDescription(selected.description ?? "").isFree}
                  />
                  Free event
                </label>

                <label htmlFor="edit-price">Price (if not free)</label>
                <input
                  id="edit-price"
                  name="price"
                  className="input"
                  type="number"
                  min={0}
                  step="0.01"
                  defaultValue={parseEventDescription(selected.description ?? "").price}
                />

                <label htmlFor="edit-capacity">Capacity</label>
                <input
                  id="edit-capacity"
                  name="capacity"
                  type="number"
                  min={1}
                  className="input"
                  defaultValue={selected.capacity}
                  required
                />

                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
                  <div>
                    <label htmlFor="edit-starts">Starts at</label>
                    <input
                      id="edit-starts"
                      name="startsAt"
                      type="datetime-local"
                      className="input"
                      defaultValue={toDateTimeLocal(selected.startsAt)}
                      required
                    />
                  </div>
                  <div>
                    <label htmlFor="edit-ends">Ends at</label>
                    <input
                      id="edit-ends"
                      name="endsAt"
                      type="datetime-local"
                      className="input"
                      defaultValue={toDateTimeLocal(selected.endsAt)}
                      required
                    />
                  </div>
                </div>

                <label htmlFor="edit-status">Status</label>
                <select
                  id="edit-status"
                  name="targetStatus"
                  className="input"
                  value={targetStatus}
                  onChange={(e) => setTargetStatus(e.target.value as AdminEvent["status"])}
                >
                  <option value="draft">draft</option>
                  <option value="published">published</option>
                  <option value="cancelled">cancelled</option>
                </select>

                <label htmlFor="edit-cancel-reason">Cancel reason (required for cancelled)</label>
                <input
                  id="edit-cancel-reason"
                  name="cancelReason"
                  className="input"
                  placeholder="Reason for cancellation"
                  required={targetStatus === "cancelled"}
                />

                <h3 style={{ margin: "16px 0 0", fontSize: 16 }}>Sessions & speakers</h3>
                <p className="muted" style={{ margin: 0, fontSize: 13 }}>
                  Update talks and times. Add empty rows below for new sessions. Leave topic title empty to skip a
                  row.
                </p>
                {scheduleLoading ? (
                  <p className="muted">Loading schedule…</p>
                ) : null}

                {[
                  ...scheduleRows,
                  ...Array.from({ length: extraNewSlots }, (_, j) => {
                    const i = j;
                    return {
                      id: "new" as const,
                      eventId: selected.id,
                      title: "",
                      description: null,
                      startsAt: selected.startsAt,
                      endsAt: selected.endsAt,
                      room: null,
                      speakers: [] as ScheduleSessionRow["speakers"],
                      isNew: true as const,
                    };
                  }),
                ].map((row, idx) => {
                  const sp = row.speakers[0];
                  const sessionKey = row.isNew ? `new-${idx}` : row.id;
                  return (
                    <div key={sessionKey} className="panel" style={{ padding: 12 }}>
                      <strong>{row.isNew ? `New session ${idx - scheduleRows.length + 1}` : `Session ${idx + 1}`}</strong>
                      <input type="hidden" name="sessionId" value={row.isNew ? "new" : row.id} />
                      <input type="hidden" name="speakerId" value={sp?.id ?? ""} />

                      <label htmlFor={`st-${sessionKey}`} style={{ marginTop: 8, display: "block" }}>
                        Talk title
                      </label>
                      <input
                        id={`st-${sessionKey}`}
                        name="sessionTopicTitle"
                        className="input"
                        defaultValue={row.title}
                        placeholder="Talk title"
                      />

                      <label htmlFor={`sd-${sessionKey}`} style={{ marginTop: 8, display: "block" }}>
                        Talk description
                      </label>
                      <input
                        id={`sd-${sessionKey}`}
                        name="sessionTopicDescription"
                        className="input"
                        defaultValue={row.description ?? ""}
                      />

                      <label htmlFor={`sr-${sessionKey}`} style={{ marginTop: 8, display: "block" }}>
                        Room
                      </label>
                      <input
                        id={`sr-${sessionKey}`}
                        name="sessionTopicRoom"
                        className="input"
                        defaultValue={row.room ?? ""}
                      />

                      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginTop: 8 }}>
                        <div>
                          <label htmlFor={`ss-${sessionKey}`}>Session starts</label>
                          <input
                            id={`ss-${sessionKey}`}
                            name="sessionStartsAt"
                            type="datetime-local"
                            className="input"
                            defaultValue={toDateTimeLocal(row.startsAt)}
                          />
                        </div>
                        <div>
                          <label htmlFor={`se-${sessionKey}`}>Session ends</label>
                          <input
                            id={`se-${sessionKey}`}
                            name="sessionEndsAt"
                            type="datetime-local"
                            className="input"
                            defaultValue={toDateTimeLocal(row.endsAt)}
                          />
                        </div>
                      </div>

                      <label htmlFor={`sn-${sessionKey}`} style={{ marginTop: 8, display: "block" }}>
                        Speaker name
                      </label>
                      <input
                        id={`sn-${sessionKey}`}
                        name="sessionSpeakerName"
                        className="input"
                        defaultValue={sp?.fullName ?? ""}
                      />

                      <label htmlFor={`sb-${sessionKey}`} style={{ marginTop: 8, display: "block" }}>
                        Speaker bio
                      </label>
                      <input
                        id={`sb-${sessionKey}`}
                        name="sessionSpeakerBio"
                        className="input"
                        defaultValue={sp?.bio ?? ""}
                      />

                      <label htmlFor={`sa-${sessionKey}`} style={{ marginTop: 8, display: "block" }}>
                        Speaker photo URL
                      </label>
                      <input
                        id={`sa-${sessionKey}`}
                        name="sessionSpeakerAvatarUrl"
                        className="input"
                        defaultValue={sp?.avatarUrl ?? ""}
                      />
                    </div>
                  );
                })}

                <button type="button" className="button secondary" onClick={() => setExtraNewSlots((n) => n + 1)}>
                  + Add session
                </button>

                <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                  <SubmitButton className="button" idleLabel="Save all" pendingLabel="Saving..." />
                  <button type="button" className="button secondary" onClick={discardEdit}>
                    Discard edits
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      ) : null}
    </>
  );
}
