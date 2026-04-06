# Backend manual test checklist

## 1) Duplicate registration (expect conflict)

After a successful `register`, run the same `POST .../register` again with the same user token.

Expected: HTTP **409** (or JSON `error.code` = `CONFLICT`).

## 2) Check-in (REST)

Staff roles: `team_member`, `organizer`, `super_admin`.

Promote your test user (example):

```sql
UPDATE users SET role = 'team_member' WHERE email = 'you@example.com';
```

Restart the server if it caches nothing (role is read from DB each request).

**QR check-in**

```bash
curl -s -X POST "http://localhost:8081/v1/events/${EVENT_ID}/checkin/qr" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"qrCode\":\"${QR_FROM_TICKET}\"}"
```

**Manual check-in**

```bash
curl -s -X POST "http://localhost:8081/v1/registrations/${REGISTRATION_ID}/checkin/manual" \
  -H "Authorization: Bearer ${TOKEN}"
```

Second check-in on the same registration should return **409** with `ALREADY_CHECKED_IN`.

## 3) GraphQL

- Playground: `http://localhost:8081/playground`
- Endpoint: `POST http://localhost:8081/graphql` with header `Authorization: Bearer <idToken>`

Example:

```graphql
query {
  me { id email role }
}
```

```graphql
mutation {
  registerForEvent(eventId: "EVENT_UUID") {
    id
    qrCodeValue
  }
}
```

Other schema fields may return `not implemented` until wired in `gqlgen/resolver.go`.
