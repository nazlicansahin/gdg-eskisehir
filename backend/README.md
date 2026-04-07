# Backend Foundation

This backend follows:

- DDD (domain core)
- Clean Architecture (layered boundaries)
- Hexagonal Architecture (ports/adapters)

## Folder map

- `internal/domain`: entities, value objects, enums
- `internal/application`: use cases, policies, ports
- `internal/infrastructure`: adapter implementations (DB, Firebase, secrets, providers)
- `internal/interface/graphql`: resolver entry points (thin)
- `shared/errors`: sentinel errors and GraphQL error code mapping
- `schema/graphql`: GraphQL schema files (`.graphqls`)

## Rule reminders

- Resolvers stay thin: parse input -> use case -> map output
- Business rules live in application/use case layer
- Authorization is centralized in policy layer
- Do not manually edit generated SDK folders
- If `.graphqls` changes:
  1. `make generate` or `go generate` for gqlgen
  2. `make generate-all` for SDK generation

## Run locally

Prerequisites:

- PostgreSQL running and migrations applied (`internal/infrastructure/postgres/migrations/0001_phase1_core.sql` then `0002_user_roles.sql`)
- Repo root `.env.local` with `BACKEND_DB_DSN`, `BACKEND_FIREBASE_PROJECT_ID`, `BACKEND_FIREBASE_SERVICE_ACCOUNT_JSON_BASE64`

From `backend/`:

```bash
make test
go run ./cmd/server
```

If you see `address already in use` on `:8080`, either free the port or set another bind address in repo root `.env.local`:

```env
HTTP_ADDR=:8081
```

Find what holds a port on macOS:

```bash
lsof -nP -iTCP:8080 -sTCP:LISTEN
```

HTTP:

- `GET /healthz`
- `POST /v1/events/{eventID}/register` (requires `Authorization: Bearer <Firebase ID token>`)
- `GET /v1/events/{eventID}/ticket` (requires Bearer token)
- `POST /v1/events/{eventID}/checkin/qr` (staff role; JSON body `{"qrCode":"..."}`)
- `POST /v1/registrations/{registrationID}/checkin/manual` (staff role)

GraphQL:

- `GET /playground` — GraphQL Playground UI
- `POST /graphql` — same Bearer auth as REST

After changing `schema/graphql/schema.graphqls`, run `make generate` (gqlgen), then implement new resolvers in `gqlgen/resolver.go`.

Users have **multiple roles** (`user_roles` table): baseline `member` plus optional `team_member`, `crew`, `organizer`, `super_admin`. **`organizer`** may `grantUserRole` / `revokeUserRole` for `team_member` and `crew` only; **`super_admin`** may grant or revoke any role except revoking baseline `member`. **`team_member`**, **`crew`**, **`organizer`**, and **`super_admin`** may perform QR / manual check-in (REST or GraphQL).

See `docs/backend-testing.md` for curl examples.

Insert a published event row in Postgres for manual testing (example UUID and timestamps):

```sql
INSERT INTO events (id, title, status, capacity, starts_at, ends_at)
VALUES (
  gen_random_uuid(),
  'Test event',
  'published',
  100,
  now() + interval '1 day',
  now() + interval '2 days'
)
RETURNING id::text;
```

Use the returned `id` as `{eventID}` in the URLs above.
