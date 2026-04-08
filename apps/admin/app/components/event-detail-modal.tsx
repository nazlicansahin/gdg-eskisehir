"use client";

import { useState } from "react";
import Link from "next/link";
import type { AdminEvent } from "@/lib/types";
import SubmitButton from "./submit-button";

type Props = {
  events: AdminEvent[];
  onUpdate: (formData: FormData) => Promise<void>;
};

function toDateTimeLocal(iso: string): string {
  const date = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(
    date.getHours(),
  )}:${pad(date.getMinutes())}`;
}

function extractImageUrls(text: string): string[] {
  const urls = text.match(/https?:\/\/[^\s)]+/g) ?? [];
  return urls.filter((url) => /\.(png|jpe?g|gif|webp|avif|svg)$/i.test(url));
}

export default function EventDetailModal({ events, onUpdate }: Props) {
  const [selected, setSelected] = useState<AdminEvent | null>(null);
  const [editMode, setEditMode] = useState(false);
  const [targetStatus, setTargetStatus] = useState<AdminEvent["status"]>("draft");

  const openDetails = (event: AdminEvent) => {
    setSelected(event);
    setEditMode(false);
    setTargetStatus(event.status);
  };

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
                <button
                  type="button"
                  className="link-button"
                  onClick={() => openDetails(event)}
                >
                  {event.title}
                </button>
              </td>
              <td>{event.status}</td>
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
          <div className="modal-card panel">
            <div className="modal-header">
              <div>
                <h2 style={{ margin: 0 }}>{selected.title}</h2>
                <p className="muted" style={{ marginTop: 6 }}>
                  Status: {selected.status}
                </p>
              </div>
              <button
                type="button"
                className="button secondary"
                onClick={() => {
                  setSelected(null);
                  setEditMode(false);
                }}
              >
                Close
              </button>
            </div>

            {!editMode ? (
              <div style={{ display: "grid", gap: 10 }}>
                <div>
                  <strong>Description:</strong>
                  <p className="muted">{selected.description || "No description"}</p>
                  {extractImageUrls(selected.description ?? "").length > 0 ? (
                    <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginTop: 8 }}>
                      {extractImageUrls(selected.description ?? "").map((url) => (
                        <img
                          key={url}
                          src={url}
                          alt="Event image"
                          style={{ width: 180, height: 120, objectFit: "cover", borderRadius: 8 }}
                        />
                      ))}
                    </div>
                  ) : null}
                </div>
                <div>
                  <strong>Capacity:</strong> {selected.capacity}
                </div>
                <div>
                  <strong>Starts:</strong> {new Date(selected.startsAt).toLocaleString()}
                </div>
                <div>
                  <strong>Ends:</strong> {new Date(selected.endsAt).toLocaleString()}
                </div>

                <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
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
                style={{ display: "grid", gap: 10 }}
                onSubmit={() => {
                  setSelected(null);
                  setEditMode(false);
                }}
              >
                <input type="hidden" name="eventId" value={selected.id} />
                <input type="hidden" name="previousStatus" value={selected.status} />
                <label htmlFor="edit-title">Title</label>
                <input id="edit-title" name="title" className="input" defaultValue={selected.title} required />

                <label htmlFor="edit-description">Description</label>
                <textarea
                  id="edit-description"
                  name="description"
                  className="input"
                  defaultValue={selected.description ?? ""}
                  rows={4}
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

                <div style={{ display: "flex", gap: 8 }}>
                  <SubmitButton className="button" idleLabel="Save" pendingLabel="Saving..." />
                  <button
                    type="button"
                    className="button secondary"
                    onClick={() => {
                      setSelected(null);
                      setEditMode(false);
                    }}
                  >
                    Cancel
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
