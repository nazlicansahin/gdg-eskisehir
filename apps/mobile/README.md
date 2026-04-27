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

## Calendar

**Add to calendar** uses [`add_2_calendar`](https://pub.dev/packages/add_2_calendar): it opens the system calendar editor with title, start/end (local time), optional description body and **Location:** line from the parsed event description, and on iOS a one-hour reminder before start. Entry points: **Event detail** (info card) and **Ticket** (when the event payload is loaded).

iOS requires `NSCalendarsUsageDescription` (and `NSContactsUsageDescription` is recommended by the plugin). Android may need the `INSERT` calendar intent in `<queries>` (see plugin README) so the calendar app can be resolved on API 30+.

## Future (mobile backlog)

Ideas not implemented yet; track and prioritise as needed.

- **Venue / map** — surface a structured venue or coordinates from the backend when the API exposes them; open in Maps using `url_launcher` or an embedded map.
- **Participation badges** — badge or achievement-style rewards for events the user joined or attended (depends on clear attendance signals from the backend, e.g. check-in or completed registration); surface on profile, ticket history, or a dedicated collection screen.
- **Share sheet** — share human-readable text plus a deep link (`go_router` / universal links or a custom scheme) so recipients can open the event in the app or on the web.
- **Local reminder for upcoming events** — schedule a `flutter_local_notifications` reminder from the device (distinct from push), with user consent and clear cancellation when the event is past or registration is cancelled.
- **Apple Wallet / Google Wallet** — add tickets as passes; typically requires server-generated **`.pkpass`** (Apple) and the Android Wallet APIs / pass format, plus signing certificates.
- **i18n polish** — e.g. Turkish labels for event time filter chips, aligned with app locale once end-to-end l10n is chosen.
- **Data model follow-ups** — extend the GraphQL/event entity when backend adds venue fields or public event URLs so calendar, map, and share flows stay consistent.

## Reverse-engineering hardening

This app now includes baseline static hardening:

- Android release enables R8 (`isMinifyEnabled=true`, `isShrinkResources=true`).
- Android cleartext traffic is disabled (`usesCleartextTraffic=false` + network security config).
- Android backups are disabled (`allowBackup=false`, `fullBackupContent=false`).
- iOS App Transport Security disallows arbitrary HTTP loads.

For production releases, build with Dart obfuscation and keep debug symbols outside the APK/IPA:

```bash
# Android (preferred release artifact)
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols/android

# iOS
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/symbols/ios
```

Important operational guidance:

- Never ship with debug signing keys; configure release signing in CI/CD.
- Keep symbol files in secure artifact storage for crash deobfuscation.
- Keep business-critical authorization in backend policy/use cases (do not trust client-side gates).
- Treat Firebase config as public metadata, and protect secrets/tokens only on server side.

Runtime checks currently include root/jailbreak, Android developer mode, and emulator/virtual-device signals. By default they are enforced in release builds. You can force enforcement in debug/profile for verification:

```bash
flutter run --dart-define=ENFORCE_ANTI_TAMPER=true
```
