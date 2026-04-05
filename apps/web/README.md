# User-Facing Website (Phase 1)

## Product boundary

This is a user-facing product, not a marketing-only landing page.

## Route map

- `/`
- `/events`
- `/events/[id]`
- `/events/[id]/schedule`
- `/speakers`
- `/speakers/[id]`
- `/tickets`
- `/profile`
- `/auth/*`

## Experience differences vs mobile

Allowed differences:

- denser list/table layouts
- richer filtering/search on larger screens
- keyboard navigation improvements

Not allowed differences:

- any mismatch in core domain behavior (registration, capacity, visibility, QR validity)

## Security guardrail

- Only public config can go to browser bundles.
- Any secret-bearing operation must execute server-side or via backend API.
