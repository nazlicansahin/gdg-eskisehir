# Flutter Mobile App (Phase 1)

## Navigation structure

- Bottom tabs:
  - Home (Events)
  - My Tickets
  - Schedule
  - Speakers
  - Profile

## Primary flows

1. Auth -> event list -> event detail -> register -> ticket/QR
2. My tickets -> ticket detail -> QR full screen
3. Speakers list -> speaker detail
4. Profile view/edit

## Role-aware behavior

- Default user scope is `member`.
- Optional operational entry points for check-in are displayed only for allowed roles.

## Feature parity contract

The following capabilities must match website behavior exactly (domain rules):

- event visibility and statuses
- one registration per event per user
- capacity-closed registration blocking
- QR ticket semantics
