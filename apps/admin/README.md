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
