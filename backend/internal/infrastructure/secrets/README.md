# Secret Retrieval Strategy

Phase 1 runtime rule:

- backend reads real secrets from Google Cloud Secret Manager
- local development may use gitignored `.env.local`

## Expected secret names

- `gdg-<env>-runtime-jwt-signing-key`
- `gdg-<env>-runtime-firebase-admin-json`
- `gdg-<env>-infra-postgres-dsn`
- `gdg-<env>-infra-redis-password`
- `gdg-<env>-thirdparty-email-api-key`
- `gdg-<env>-thirdparty-push-api-key`

## Runtime approach

1. Resolve `APP_ENV` (`dev`, `staging`, `prod`).
2. Build secret IDs from naming convention.
3. Read secret versions using service account with least privilege.
4. Keep secret values in memory only.
5. Never print secret values in logs.
