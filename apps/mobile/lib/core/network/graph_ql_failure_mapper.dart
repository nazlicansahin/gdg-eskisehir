import 'package:gdg_events/core/errors/failures.dart';
import 'package:graphql/client.dart';

/// Maps GraphQL [OperationException] and transport errors to [Failure].
Failure mapGraphQlException(Object error, StackTrace _) {
  if (error is OperationException) {
    final gqlErr =
        error.graphqlErrors.isNotEmpty ? error.graphqlErrors.first : null;
    final code = gqlErr?.extensions?['code']?.toString();
    final msg = gqlErr?.message ??
        error.linkException?.originalException.toString() ??
        'GraphQL error';
    return GraphQlFailure(msg, code: code);
  }
  return UnknownFailure(error.toString());
}
