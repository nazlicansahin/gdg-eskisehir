# Thin Resolver Guidelines

Resolvers in this codebase should follow this sequence:

1. Parse and validate transport-level input shape (required fields, type conversion).
2. Extract auth context (firebase UID, user role, request metadata).
3. Build use case input DTO.
4. Call exactly one use case for the business action.
5. Map use case output to GraphQL response type.
6. Map errors using `shared/errors.ToGraphQLCode`.

Do not:

- perform business rule checks in resolvers
- query repositories directly from resolvers
- duplicate RBAC checks that already exist in policy/use case layer
