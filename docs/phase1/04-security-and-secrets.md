# Security and Secrets Blueprint (Phase 1)

## Secret categories

1. App runtime
   - JWT signing key
   - Firebase Admin credentials
2. Infrastructure
   - Postgres credentials
   - Redis credentials
3. Third-party integration
   - Email provider API key
   - Push provider API key
4. CI/CD and deploy
   - Container registry auth
   - Deployment tokens

## Public config vs real secret

Public config allowed in clients:

- Firebase client config
- Public API base URL
- Public analytics IDs

Real secrets (never client-side):

- Any key that grants privileged access, signing, or admin actions

## Google Cloud Secret Manager strategy

- Store all runtime secrets in Google Cloud Secret Manager.
- Backend runtime identity (service account/workload identity) reads only required secrets.
- Grant least privilege IAM at secret level where possible.
- Use secret versions for rotation.

## Naming convention

Use:

`<app>-<env>-<category>-<name>`

Examples:

- `gdg-dev-runtime-jwt-signing-key`
- `gdg-staging-infra-postgres-password`
- `gdg-prod-thirdparty-email-api-key`

## Environment separation

- Separate projects or strict namespace partitioning for `dev`, `staging`, `prod`.
- No credential reuse across environments.
- Separate credentials for app runtime and migration jobs.

## Local development

- Use gitignored local env files only:
  - `.env.local` (not committed)
  - `.env.template` (safe placeholder template, committed)
- Never place real secret values in repository files.

## CI and deployment handling

- CI runner fetches secrets at runtime from secure store.
- Avoid logging env values or full command traces with secret interpolation.
- Disable shell debug modes that leak env values.
- Use scoped short-lived tokens where available.

## Logging and redaction policy

- Structured logs only.
- Redact tokens, API keys, Authorization headers, cookies, secret-looking strings.
- Never return secret values in GraphQL errors/debug traces.
- Disable verbose debug output in production.

## Rotation policy

- Quarterly scheduled rotation for high-impact secrets minimum.
- Immediate rotation on suspected exposure.
- Keep documented runbook for emergency rotation.
- Prefer dual-read and controlled cutover when rotation can break consumers.

## Next.js and Flutter specific rules

- Next.js:
  - only server-side code can read private secrets
  - never prefix real secrets with `NEXT_PUBLIC_`
- Flutter:
  - never embed backend/admin secrets
  - all secret-bearing third-party calls must go through backend

## SDK and build leak prevention

- Generated SDKs must never include runtime secrets.
- Add secret scanning in pre-commit and CI pipeline.
- Block commits if high-confidence secret patterns are detected.
