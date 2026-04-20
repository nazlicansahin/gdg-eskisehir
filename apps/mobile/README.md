# Flutter mobile app (Phase 1)

## Architecture (clean, backend-aligned)

Layers match the Go backend’s intent: **domain rules live on the server**; the app maps API data to entities and handles UX.

| Layer | Responsibility |
|--------|----------------|
| **domain/** | Entities (`Event`, `RegistrationTicket`, `AppUser`), enums, **repository interfaces** only. No Flutter/Firebase imports. |
| **data/** | Repository implementations: Firebase Auth, GraphQL documents, `Either` → `Failure` mapping. |
| **presentation/** | Widgets, Riverpod providers (`FutureProvider`, `StreamProvider`), navigation triggers. |

Cross-cutting code lives under **`lib/core/`** (config, failures, GraphQL client factory) and **`lib/app/`** (DI `Provider`s, router).

Depend on abstractions: UI and providers depend on **`EventsRepository`** / **`RegistrationsRepository`** / **`AuthRepository`**, not on concrete clients.

## Primary flows (MVP wired)

1. Firebase Auth (email / password) → GraphQL with `Authorization: Bearer <ID token>`.
2. **Events** list → detail → **Register** → **Ticket** (QR).
3. **My tickets** lists `myRegistrations`; **Profile** shows user + sign-out.

Schedule / Speakers tabs from the product README can be added as separate features using the same **domain / data / presentation** layout.

## Project bootstrap

This repo ships **`pubspec.yaml`** and **`lib/`** only. Generate platform runners once:

```bash
cd apps/mobile
flutter pub get
flutter create --platforms=android,ios .
```

This adds `android/` and `ios/` (and optional `web/`) without clobbering `lib/`. If `flutter create` warns about an existing project, choose to update only missing files.

Then replace **`lib/firebase_options.dart`** with output from:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

## Pointing at the API

Default API URL is `http://127.0.0.1:8081`. Override per runtime target:

```bash
# iOS Simulator (host localhost is reachable)
flutter run -d ios --dart-define=API_BASE_URL=http://127.0.0.1:8081

# Android Emulator (host machine is 10.0.2.2)
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8081

# Physical iPhone on same Wi-Fi as your Mac
flutter run -d <ios-device-id> --dart-define=API_BASE_URL=http://<YOUR_MAC_LAN_IP>:8081
```

Notes:

- Use your Mac LAN IP (for example `192.168.1.5`) for physical iOS/Android devices.
- Ensure backend is running and healthy at `http://localhost:8081/healthz`.
- If wireless device debugging is unstable, test once with USB to rule out network noise.

## Legal site (Profile links)

The app can open your published `apps/web` legal pages (Privacy, Terms, Support) from **Profile** when you pass the public **HTTPS** site origin (no trailing slash):

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8081 \
  --dart-define=LEGAL_SITE_BASE_URL=https://your-production-site.example
```

If `LEGAL_SITE_BASE_URL` is omitted, the Legal section is hidden (useful for local dev before the site is live).

## Navigation structure (target)

- Bottom tabs: **Events**, **My Tickets**, **Profile** (implemented).
- Optional later: **Schedule**, **Speakers** (see repo `apps/mobile` product notes in git history / phase docs).

## Feature parity contract

Same invariants as the website: published-only discovery for members, one registration per event, capacity and QR semantics enforced by the backend (`docs/phase1/01-assumptions-and-guardrails.md`).
