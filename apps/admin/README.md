# Admin Panel (Phase 1)

## Product boundary

Admin panel is a separate privileged surface from the user-facing website.

## Sidebar IA

- Dashboard
- Events
  - Draft
  - Published
  - Cancelled
- Sessions
- Speakers
- Registrations
- Check-ins
- Users & Roles (super_admin)
- Settings (super_admin)

## Core admin flows

- create/edit/publish/cancel events
- manage sessions and speakers
- view registrations
- check-in by QR and manual action
- cancel registration (super_admin only)
- assign user roles (super_admin only)

## RBAC enforcement

Every protected action must be gated at:

1. route level
2. GraphQL resolver level
3. use case policy level

## Current implementation status

Implemented organizer panel pages:

- `/login` (Firebase email/password)
- `/events`
- `/events/[id]/registrations`
- `/users`
- `/checkin`

Implemented behavior highlights:

- Role-aware route guard (`organizer` or `super_admin`)
- Logout action (token cookie cleared server-side)
- Users & Roles:
  - add role via dropdown (`team_member`, `crew`, `organizer`)
  - remove role via role chip close icon
  - prevent self-organizer revoke
- Check-in:
  - QR and manual check-in forms
  - success/error notice banner
  - GraphQL error code -> user-friendly message mapping
- Events list:
  - title search
  - status filter (`draft/published/cancelled/all`)
  - create event modal (3-step wizard)
    - step 1: name, description, dates, capacity
    - step 2: speaker/topic pairs (creates speakers + sessions)
    - step 3: location, event image URL, free/price

## Run locally

From `apps/admin`:

```bash
npm install
npm run dev
```

## Smoke test checklist

1. Login with an organizer account.
2. Open `/users`:
   - add `team_member` to a user
   - remove `team_member` from role chip close icon
3. Open `/checkin`:
   - test QR check-in with valid `eventId` + `qrCode`
   - test manual check-in with `registrationId`
4. Open `/events`:
   - search by title
   - filter by status
   - create a new event via modal wizard

## Local troubleshooting

- `Cannot find module './xxx.js'` in `.next/server/...`:
  - stop all `next dev` processes
  - delete `apps/admin/.next`
  - restart dev server
- Frequent watcher errors (`EMFILE`):
  - avoid multiple `next dev` processes for this app
  - start with polling if needed:
    - `WATCHPACK_POLLING=true npm run dev`
