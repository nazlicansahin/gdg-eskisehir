# Data and API Design (Single Organization)

## Database schema (Phase 1)

No organization tables are present by design.

### `users`

- `id` UUID PK
- `firebase_uid` TEXT UNIQUE NOT NULL
- `email` TEXT UNIQUE NOT NULL
- `display_name` TEXT NOT NULL
- `role` TEXT NOT NULL CHECK role IN (`member`, `team_member`, `organizer`, `super_admin`)
- audit columns: `created_at`, `updated_at`, `updated_by`

### `events`

- `id` UUID PK
- `slug` TEXT UNIQUE
- `title`, `description`, `location`
- `status` TEXT NOT NULL CHECK status IN (`draft`, `published`, `cancelled`)
- `capacity` INT NOT NULL CHECK capacity >= 0
- `starts_at`, `ends_at` TIMESTAMP WITH TIME ZONE
- audit columns

### `sessions`

- `id` UUID PK
- `event_id` UUID FK -> `events.id`
- `title`, `description`, `room`
- `starts_at`, `ends_at`
- `sort_order` INT
- audit columns

### `speakers`

- `id` UUID PK
- `full_name` TEXT NOT NULL
- `bio` TEXT
- `avatar_url` TEXT
- `social_links` JSONB
- audit columns

### `session_speakers`

- `session_id` UUID FK -> `sessions.id`
- `speaker_id` UUID FK -> `speakers.id`
- PK (`session_id`, `speaker_id`)

### `registrations`

- `id` UUID PK
- `event_id` UUID FK -> `events.id`
- `user_id` UUID FK -> `users.id`
- `status` TEXT NOT NULL CHECK status IN (`active`, `cancelled`)
- `qr_code_value` TEXT UNIQUE NOT NULL
- `checked_in_at` TIMESTAMP WITH TIME ZONE NULL
- `cancelled_reason` TEXT NULL
- audit columns
- UNIQUE (`event_id`, `user_id`)

### `checkins`

- `id` UUID PK
- `registration_id` UUID FK -> `registrations.id`
- `event_id` UUID FK -> `events.id`
- `method` TEXT CHECK method IN (`qr`, `manual`)
- `checked_in_by` UUID FK -> `users.id`
- `checked_in_at` TIMESTAMP WITH TIME ZONE NOT NULL

### `notifications`

- `id` UUID PK
- `user_id` UUID FK -> `users.id`
- `type` TEXT NOT NULL
- `payload` JSONB NOT NULL
- `scheduled_at` TIMESTAMP WITH TIME ZONE NULL
- `sent_at` TIMESTAMP WITH TIME ZONE NULL
- `status` TEXT NOT NULL

## Critical constraints

- One registration per user/event: UNIQUE (`event_id`, `user_id`)
- Capacity guard is transactional on registration creation
- QR validation key: (`event_id`, `qr_code_value`)

## GraphQL surface

### User-facing queries

- `me`
- `events(filter)`
- `event(id)`
- `eventSchedule(eventId)`
- `speakers(filter)`
- `speaker(id)`
- `myRegistrations`
- `myTicket(eventId)`

### User-facing mutations

- `registerForEvent(eventId)`
- `updateMyProfile(input)`

### Admin queries

- `adminEvents(filter)`
- `adminEvent(id)`
- `adminRegistrations(eventId, filter)`
- `adminUsers(filter)`

### Admin mutations

- `createEvent(input)`
- `updateEvent(input)`
- `publishEvent(eventId)`
- `cancelEvent(eventId, reason)`
- `createSession(input)`
- `updateSession(input)`
- `createSpeaker(input)`
- `updateSpeaker(input)`
- `attachSpeakerToSession(sessionId, speakerId)`
- `checkInByQR(eventId, qrCode)`
- `manualCheckIn(registrationId)`
- `cancelRegistration(registrationId, reason)` (super_admin)
- `assignUserRole(userId, role)` (super_admin)

## Use-case oriented resolver pattern

- Resolver accepts request and auth context
- Resolver calls one use case
- Use case performs validation + authorization + transaction
- Resolver maps output and sentinel errors to GraphQL response
