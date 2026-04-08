"use client";

import { useState } from "react";
import SubmitButton from "./submit-button";

type Props = {
  action: (formData: FormData) => Promise<void>;
};

const stepTitle: Record<number, string> = {
  1: "Event basics",
  2: "Speakers and topics",
  3: "Logistics and pricing",
};

export default function CreateEventModal({ action }: Props) {
  const [open, setOpen] = useState(false);
  const [step, setStep] = useState(1);
  const [speakerCount, setSpeakerCount] = useState(1);

  const canGoBack = step > 1;
  const canGoNext = step < 3;

  return (
    <>
      <button
        type="button"
        className="button"
        onClick={() => {
          setStep(1);
          setSpeakerCount(1);
          setOpen(true);
        }}
      >
        Create New Event
      </button>

      {open ? (
        <div className="modal-overlay" role="dialog" aria-modal="true" aria-label="Create event">
          <div className="modal-card panel">
            <div className="modal-header">
              <div>
                <h2 style={{ margin: 0 }}>Create event</h2>
                <p className="muted" style={{ marginTop: 6 }}>
                  Step {step}/3 - {stepTitle[step]}
                </p>
              </div>
              <button type="button" className="button secondary" onClick={() => setOpen(false)}>
                Close
              </button>
            </div>

            <form
              action={action}
              onSubmit={() => {
                if (step === 3) {
                  setOpen(false);
                }
              }}
            >
              <section style={{ display: step === 1 ? "block" : "none" }}>
                <label htmlFor="title">Event name</label>
                <input id="title" name="title" className="input" required placeholder="GDG Meetup" />

                <label htmlFor="description" style={{ marginTop: 12, display: "block" }}>
                  Description
                </label>
                <textarea
                  id="description"
                  name="description"
                  className="input"
                  rows={4}
                  placeholder="Event details..."
                />

                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
                  <div>
                    <label htmlFor="startsAt">Starts at</label>
                    <input id="startsAt" name="startsAt" className="input" type="datetime-local" required />
                  </div>
                  <div>
                    <label htmlFor="endsAt">Ends at</label>
                    <input id="endsAt" name="endsAt" className="input" type="datetime-local" required />
                  </div>
                </div>

                <label htmlFor="capacity" style={{ marginTop: 12, display: "block" }}>
                  Capacity
                </label>
                <input
                  id="capacity"
                  name="capacity"
                  className="input"
                  type="number"
                  min={1}
                  defaultValue={100}
                  required
                />
              </section>

              <section style={{ display: step === 2 ? "block" : "none" }}>
                <div style={{ marginBottom: 12 }}>
                  <label htmlFor="speakerCount">Speaker/topic pair count</label>
                  <select
                    id="speakerCount"
                    className="input"
                    value={speakerCount}
                    onChange={(e) => setSpeakerCount(Number(e.target.value))}
                  >
                    <option value={1}>1 pair</option>
                    <option value={2}>2 pairs</option>
                    <option value={3}>3 pairs</option>
                    <option value={4}>4 pairs</option>
                    <option value={5}>5 pairs</option>
                  </select>
                </div>
                {Array.from({ length: speakerCount }, (_, idx) => (
                  <div key={idx} className="panel" style={{ marginBottom: 10 }}>
                    <strong>Pair {idx + 1}</strong>
                    <label htmlFor={`speakerName-${idx}`} style={{ marginTop: 8, display: "block" }}>
                      Speaker name
                    </label>
                    <input
                      id={`speakerName-${idx}`}
                      name="speakerName"
                      className="input"
                      placeholder="Jane Doe"
                    />
                    <label htmlFor={`speakerBio-${idx}`} style={{ marginTop: 8, display: "block" }}>
                      Speaker bio
                    </label>
                    <input
                      id={`speakerBio-${idx}`}
                      name="speakerBio"
                      className="input"
                      placeholder="Google Developer Expert..."
                    />
                    <label htmlFor={`speakerAvatarUrl-${idx}`} style={{ marginTop: 8, display: "block" }}>
                      Speaker photo URL
                    </label>
                    <input
                      id={`speakerAvatarUrl-${idx}`}
                      name="speakerAvatarUrl"
                      className="input"
                      placeholder="https://..."
                    />
                    <label htmlFor={`topicTitle-${idx}`} style={{ marginTop: 8, display: "block" }}>
                      Talk topic
                    </label>
                    <input
                      id={`topicTitle-${idx}`}
                      name="topicTitle"
                      className="input"
                      placeholder="Building AI agents"
                    />
                    <label htmlFor={`topicDescription-${idx}`} style={{ marginTop: 8, display: "block" }}>
                      Topic description
                    </label>
                    <input
                      id={`topicDescription-${idx}`}
                      name="topicDescription"
                      className="input"
                      placeholder="Hands-on journey..."
                    />
                    <label htmlFor={`topicRoom-${idx}`} style={{ marginTop: 8, display: "block" }}>
                      Room (optional)
                    </label>
                    <input id={`topicRoom-${idx}`} name="topicRoom" className="input" placeholder="Main hall" />
                  </div>
                ))}
              </section>

              <section style={{ display: step === 3 ? "block" : "none" }}>
                <label htmlFor="location">Address / location</label>
                <input id="location" name="location" className="input" placeholder="Eskisehir / Venue name" />

                <label htmlFor="eventImageUrl" style={{ marginTop: 12, display: "block" }}>
                  Event photo URL
                </label>
                <input id="eventImageUrl" name="eventImageUrl" className="input" placeholder="https://..." />

                <div style={{ marginTop: 12 }}>
                  <label htmlFor="isFree" style={{ display: "inline-flex", gap: 8 }}>
                    <input id="isFree" name="isFree" type="checkbox" defaultChecked />
                    Free event
                  </label>
                </div>

                <label htmlFor="price" style={{ marginTop: 12, display: "block" }}>
                  Price (if not free)
                </label>
                <input id="price" name="price" className="input" type="number" min={0} step="0.01" />
              </section>

              <div style={{ display: "flex", justifyContent: "space-between", marginTop: 14 }}>
                <button
                  type="button"
                  className="button secondary"
                  disabled={!canGoBack}
                  onClick={() => setStep((value) => Math.max(1, value - 1))}
                >
                  Back
                </button>

                {canGoNext ? (
                  <button
                    type="button"
                    className="button"
                    onClick={() => setStep((value) => Math.min(3, value + 1))}
                  >
                    Next
                  </button>
                ) : (
                  <SubmitButton idleLabel="Create event" pendingLabel="Creating..." className="button" />
                )}
              </div>
            </form>
          </div>
        </div>
      ) : null}
    </>
  );
}
