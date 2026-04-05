# Backend Foundation (DDD + Clean + Hexagonal)

## Layer boundaries

1. Domain layer (`backend/internal/domain`)
   - Pure entities, value objects, enums, domain rules
   - No framework/infrastructure imports

2. Application layer (`backend/internal/application`)
   - Use cases and orchestration
   - Policy checks (RBAC) and validation
   - Repository/service interfaces (ports)

3. Infrastructure layer (`backend/internal/infrastructure`)
   - Postgres repositories
   - Firebase token verification adapter
   - Secret manager adapter
   - Notification providers

4. Interface layer (`backend/internal/interface`)
   - GraphQL resolvers
   - HTTP middleware (auth context extraction)
   - Error mapping

## Resolver contract

Resolvers must only:

- Parse input
- Extract auth context
- Call a use case
- Map output/error to GraphQL model

Resolvers must not:

- Perform business validation directly
- Encode authorization logic inline
- Access database directly

## RBAC policy entry points

- `CanCreateEvent(actorRole)`
- `CanPublishEvent(actorRole)`
- `CanCheckIn(actorRole)`
- `CanCancelRegistration(actorRole)`
- `CanManageRoles(actorRole)`

Policy checks run in use case layer, not scattered across resolvers.

## Sentinel error model

`shared/errors` must expose stable sentinel errors:

- `ErrUnauthorized`
- `ErrForbidden`
- `ErrNotFound`
- `ErrValidation`
- `ErrConflict`
- `ErrAlreadyRegistered`
- `ErrCapacityReached`
- `ErrInvalidQRCode`
- `ErrRegistrationCancelled`

## GraphQL error mapping

Map sentinel errors to stable `extensions.code` values:

- `ErrUnauthorized` -> `UNAUTHENTICATED`
- `ErrForbidden` -> `FORBIDDEN`
- `ErrNotFound` -> `NOT_FOUND`
- `ErrValidation` -> `VALIDATION_FAILED`
- `ErrConflict` / `ErrAlreadyRegistered` -> `CONFLICT`
- `ErrCapacityReached` -> `CAPACITY_REACHED`
- `ErrInvalidQRCode` -> `INVALID_QR_CODE`
- `ErrRegistrationCancelled` -> `REGISTRATION_CANCELLED`
