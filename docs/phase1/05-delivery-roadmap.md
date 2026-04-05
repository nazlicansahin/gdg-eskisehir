# Phase 1 Delivery Roadmap

## Stream structure

- Stream A: Backend foundation and invariants
- Stream B: User-facing parity (mobile + website)
- Stream C: Admin operations
- Stream D: Security hardening and release readiness

## Implementation order

### Milestone 1: Backend baseline

- Auth context and Firebase token verification
- Core domain entities and use case interfaces
- Sentinel errors + GraphQL error code mapping
- Events read APIs (`events`, `event`)
- Registration creation with uniqueness + capacity checks
- Ticket retrieval (`myTicket`)

### Milestone 2: User product parity

- Mobile and website implement same capability set:
  - events list/detail
  - register
  - ticket/QR
  - schedule
  - speakers
  - profile edit
- Parity checks added to QA checklist

### Milestone 3: Admin operations

- Admin auth gate and role-aware routing
- Event/session/speaker management
- Registration list
- QR/manual check-in
- Role management and registration cancellation (`super_admin` only)

### Milestone 4: Notification and hardening

- Registration success notification
- Reminder scheduling
- Logs/metrics hardening
- Security checks and secret handling validation

## First sprint (detailed)

### Sprint objective

Deliver one complete vertical flow:
`auth -> discover event -> register -> generate ticket/QR -> view ticket`.

### Sprint backlog

1. Backend
   - define and wire sentinel errors
   - implement register use case with transactional checks
   - implement `myTicket`
   - expose GraphQL queries/mutations for event discovery and registration

2. Mobile
   - auth integration
   - event list/detail
   - register CTA and ticket page

3. Website
   - auth integration
   - event list/detail
   - register CTA and ticket page

4. Admin
   - minimal protected shell
   - read-only events/registrations list for operations visibility

5. Security
   - configure secret retrieval path for backend runtime
   - verify no secrets in repository or client bundles

### Definition of done

- Both mobile and website can complete registration flow against same backend.
- Registration invariants are enforced by backend tests.
- GraphQL errors return stable `extensions.code` values.
- Secret handling policy is applied for local/dev setup.
