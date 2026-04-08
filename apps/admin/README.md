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

Implemented organizer panel skeleton pages:

- `/login` (auth placeholder)
- `/events`
- `/events/[id]/registrations`
- `/users`
- `/checkin`

Data is read from backend GraphQL via `NEXT_PUBLIC_GRAPHQL_URL` (default: `http://localhost:8081/graphql`).

## Run locally

From `apps/admin`:

```bash
npm install
npm run dev
```
