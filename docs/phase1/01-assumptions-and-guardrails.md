# Phase 1 Assumptions and Guardrails

This document converts the approved Phase 1 plan into explicit assumptions
required for implementation.

## Confirmed assumptions

1. Single organization model only
   - No organization entity
   - No membership/invitation/switching logic
   - User role lives on user record

2. Authentication and authorization split
   - Authentication: Firebase Auth
   - Authorization: backend policy layer in Go

3. Shared backend and domain rules
   - Flutter app, user website, and admin panel all use one backend
   - Core business invariants are backend-enforced

4. Event visibility model
   - `draft`: not visible in user products
   - `published`: visible and registerable
   - `cancelled`: visible with clear badge, registration blocked

## Missing points resolved for implementation

1. Super admin bootstrap
   - First `super_admin` is assigned manually through controlled bootstrap script
     or one-off SQL runbook by an authorized operator.
   - Every role change must be auditable (`updated_by`, `updated_at`).

2. Timezone policy
   - Database stores UTC timestamps.
   - API returns ISO-8601 UTC timestamps.
   - Clients localize to user locale/timezone.

3. Notification baseline in Phase 1
   - Required events:
     - `event_registration_success`
     - `event_reminder`
   - Baseline delivery:
     - in-app notification records (must)
     - email optional (nice-to-have)
     - push staged (later)

4. State model for events and registrations
   - Event status: `draft -> published -> cancelled`
   - Registration status: `active -> cancelled`
   - Cancelled registration cannot be checked in.
   - Only `super_admin` can cancel registration.

## Explicit domain invariants

- One user can register to the same event only once.
- Registration requires event status `published`.
- Registration requires capacity availability.
- QR token is unique per registration.
- Check-in validation must use both `event_id` and `qr_code`.
- Check-in operators: `team_member`, `organizer`, `super_admin`.

## Boundary guardrails

- User website is member-facing only.
- Admin panel is a separate privileged product surface.
- Never expose operational/admin fields in user-facing APIs unless required.

## Security guardrails

- Real secrets are server-side only.
- No secret is committed to repository.
- Local secrets are allowed only in gitignored local env files.
