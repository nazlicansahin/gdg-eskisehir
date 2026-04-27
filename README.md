# EsDev: Eskisehir Yazilim Etkinlikleri

EsDev is a community events platform for GDG Eskisehir, built as a multi-app repository with a shared Go backend.

## What is in this repository

- `apps/mobile`: Flutter app for attendees and staff (events, tickets, QR check-in, profile, notifications)
- `apps/admin`: Next.js admin app for organizers (event operations, registrations, roles, check-in, sponsors)
- `apps/web`: Next.js public/legal website (home + privacy/terms/support pages with localization)
- `backend`: Go API with GraphQL + selected REST endpoints, PostgreSQL persistence, Firebase auth verification
- `docs/phase1`: phase assumptions, guardrails, and implementation references

## Architecture summary

### Backend

Backend uses:

- Domain-Driven Design (DDD)
- Clean Architecture (dependency direction)
- Hexagonal Architecture (ports/adapters)

Core layering:

- `backend/internal/domain`: entities and domain-safe types
- `backend/internal/application`: use cases and policy rules
- `backend/internal/infrastructure`: adapters (Postgres, Firebase/FCM, crypto)
- `backend/internal/interface`: delivery (GraphQL, REST handlers, middleware)

Business invariants (capacity, registration constraints, role gates, check-in semantics) are enforced on the backend.

### Mobile

Feature-oriented Flutter clean structure:

- `domain`: entities + repository contracts
- `data`: GraphQL/Firebase implementations + mapping
- `presentation`: UI + Riverpod providers
- `core`: shared config, network, failures
- `app`: top-level providers, router, app bootstrap

### Admin/Web

- `apps/admin`: protected organizer panel with route guards and role-aware actions
- `apps/web`: localized public/legal surface (English + Turkish)

## Technology stack

- **Mobile:** Flutter, Dart, Riverpod, Firebase Auth, Firebase Messaging
- **Admin/Web:** Next.js 14, React 18, TypeScript
- **Backend:** Go 1.23, gqlgen, net/http
- **Database:** PostgreSQL 16 (pgx/pgxpool)
- **Auth:** Firebase ID token verification on backend
- **Infra/Dev:** Docker Compose, GitHub Actions CI

## Key features (current)

- Authentication (email/password with Firebase)
- Event discovery and details
- Event registration and QR ticket generation
- Staff/organizer check-in (QR and manual)
- Organizer event lifecycle (create/edit/publish/cancel)
- User role management (`member`, `team_member`, `crew`, `organizer`, `super_admin`)
- Announcements and sponsors
- Push notifications + scheduled reminders
- Legal/support pages with localization

## Prerequisites

- Docker Desktop (for containerized local stack)
- Flutter SDK (for mobile development)
- Node.js + npm (for Next.js apps)
- Go 1.23+ (for non-Docker backend development)

## Environment configuration

Create a root `.env.local` file for local development. Required backend variables:

- `BACKEND_FIREBASE_PROJECT_ID`
- `BACKEND_FIREBASE_SERVICE_ACCOUNT_JSON_BASE64`

For non-Docker backend runs, also set:

- `BACKEND_DB_DSN` (Postgres connection string)
- Optional `HTTP_ADDR` (default `:8080`)

For frontend/mobile app-specific environment values, see each app folder README:

- `apps/mobile/README.md`
- `apps/admin/README.md`
- `apps/web/README.md`

## Quick start (recommended): Docker

From repo root:

```bash
docker compose up --build
```

Services:

- `postgres`: `localhost:5432` (runs SQL files from `backend/internal/infrastructure/postgres/migrations` on first init)
- `backend`: `localhost:8081` (container port `8080`)

Useful endpoints:

- Health: `http://localhost:8081/healthz`
- GraphQL Playground: `http://localhost:8081/playground`
- GraphQL endpoint: `http://localhost:8081/graphql`

Stop stack:

```bash
docker compose down
```

Reset database volume (fresh init):

```bash
docker compose down -v
docker compose up --build
```

## Run apps locally

### Mobile app

```bash
cd apps/mobile
flutter pub get
flutter run
```

Pass API URL with dart define:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8081
```

### Admin app

```bash
cd apps/admin
npm install
npm run dev
```

### Web app

```bash
cd apps/web
npm install
npm run dev
```

## Testing on a physical phone

### Android device

Use your LAN IP:

```bash
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://<YOUR_MAC_LAN_IP>:8081
```

### iPhone device (recommended path)

Because iOS transport security is hardened, prefer HTTPS API when running on a real iPhone.

1. Keep backend running locally (`docker compose up --build`)
2. Start tunnel in a separate terminal:

```bash
ngrok http 8081
```

3. Use the HTTPS tunnel URL:

```bash
flutter run -d <ios-device-id> --dart-define=API_BASE_URL=https://<your-ngrok-domain>
```

## Security hardening notes

Mobile app includes anti-reverse-engineering baseline hardening:

- Android R8 minify + resource shrinking enabled in release
- Android backup disabled
- Android cleartext disabled
- iOS ATS restricts arbitrary HTTP loads
- Runtime anti-tamper checks (root/jailbreak, developer mode, emulator signals)
- Runtime gate enforcement by default in release mode

Force anti-tamper in debug/profile:

```bash
flutter run --dart-define=ENFORCE_ANTI_TAMPER=true
```

Build obfuscated production artifacts:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/android
flutter build ipa --release --obfuscate --split-debug-info=build/symbols/ios
```

## Backend API surface (high level)

- REST:
  - `GET /healthz`
  - `POST /v1/events/{eventID}/register`
  - `GET /v1/events/{eventID}/ticket`
  - `POST /v1/events/{eventID}/checkin/qr`
  - `POST /v1/registrations/{registrationID}/checkin/manual`
- GraphQL:
  - `GET /playground`
  - `POST /graphql`

Authenticated endpoints require `Authorization: Bearer <Firebase ID token>`.

## Troubleshooting

- Docker daemon not running:
  - Start Docker Desktop, then run `docker info`
- Backend container exits with schema file error:
  - Rebuild image: `docker compose build backend`
- Postgres says "Skipping initialization":
  - Normal when volume already exists
- Port conflict:
  - Find process: `lsof -nP -iTCP:8081 -sTCP:LISTEN`
- iPhone cannot reach local HTTP backend:
  - Use HTTPS tunnel (ngrok) and pass that URL to `API_BASE_URL`

## Repository references

- System architecture: `ARCHITECTURE.md`
- Backend details: `backend/README.md`
- Mobile guide: `apps/mobile/README.md`
- Admin guide: `apps/admin/README.md`
- Web guide: `apps/web/README.md`
- Phase docs: `docs/phase1/`

## Notes and scope

Current implementation is Phase 1 oriented. Multi-organization tenancy, paid event flows, and waitlist complexity are intentionally out of scope for now.
