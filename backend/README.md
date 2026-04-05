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
