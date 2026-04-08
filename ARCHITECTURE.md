# Architecture Overview

This document defines the architecture baseline for the GDG Eskisehir Phase 1 codebase.

## System style

- Single backend serving multiple clients
- Shared domain invariants enforced on backend
- Role-based authorization across all surfaces
- API-first contract through GraphQL (+ selected REST endpoints)

## Backend architecture (Go)

Backend follows a combined model:

- Domain-Driven Design (DDD) for domain model boundaries
- Clean Architecture for dependency direction
- Hexagonal Architecture (Ports and Adapters) for infrastructure isolation

### Layer map

- `backend/internal/domain`
  - Entities, value objects, enums, domain-safe helpers
  - No framework or database dependencies
- `backend/internal/application`
  - Use cases, policy checks, orchestration
  - Ports (interfaces) for repositories and external services
- `backend/internal/infrastructure`
  - Adapter implementations (Postgres, Firebase auth verifier, secrets)
- `backend/internal/interface`
  - Delivery layer (GraphQL resolvers, HTTP handlers, middleware)

### Rules

- Business rules stay in application/domain, not resolvers
- Authorization checks go through centralized policy/use case flow
- Resolvers/handlers remain thin (parse input -> call use case -> map output/errors)

## Mobile architecture (Flutter)

Mobile uses feature-oriented Clean Architecture with Riverpod.

### Structure

- `apps/mobile/lib/features/<feature>/domain`
  - Entities and repository contracts
- `apps/mobile/lib/features/<feature>/data`
  - Repository implementations, DTO mapping, remote calls
- `apps/mobile/lib/features/<feature>/presentation`
  - UI pages/widgets + providers
- `apps/mobile/lib/core`
  - Shared config, networking, failure types
- `apps/mobile/lib/app`
  - App wiring (router, top-level providers)

### Rules

- UI depends on domain interfaces, not concrete data sources
- Authentication token is attached in network layer
- Domain invariants are not reimplemented on client side

## Admin/Web frontend architecture (Next.js)

Admin uses server-first Next.js patterns with route components and server actions.

### Structure

- `apps/admin/app`
  - Route-level UI and server actions
- `apps/admin/app/components`
  - Reusable UI components and modal flows
- `apps/admin/lib`
  - API client functions, auth helpers, shared types

### Rules

- Auth/session checks occur before privileged routes
- Role gates enforce `organizer` or `super_admin` access
- GraphQL operations are centralized in `lib/api.ts`
- UI handles friendly messaging; backend remains source of truth for rules

## Cross-surface consistency

- Core event/registration/check-in semantics are backend-enforced
- Mobile, admin, and future website must follow backend error/status contracts
- Any new user-facing behavior should be validated against backend policy and tests

## Non-goals (Phase 1)

- Multi-tenant organization model
- Divergent business rules per client
- Client-side trust for authorization decisions
