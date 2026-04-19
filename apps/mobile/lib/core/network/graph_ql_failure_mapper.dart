import 'package:gdg_events/core/errors/failures.dart';
import 'package:graphql/client.dart';

/// Maps GraphQL [OperationException] and transport errors to [Failure].
Failure mapGraphQlException(Object error, StackTrace _) {
  if (error is OperationException) {
    final gqlErr =
        error.graphqlErrors.isNotEmpty ? error.graphqlErrors.first : null;

    // HTTP link puts GraphQL errors in ServerException.parsedResponse only;
    // graphqlErrors on OperationException may stay empty.
    String? fromServerBody;
    String? codeFromBody;
    final link = error.linkException;
    if (link is ServerException) {
      final errs = link.parsedResponse?.errors;
      if (errs != null && errs.isNotEmpty) {
        final first = errs.first;
        fromServerBody = first.message;
        codeFromBody = first.extensions?['code']?.toString();
      }
    }

    final code =
        gqlErr?.extensions?['code']?.toString() ?? codeFromBody;

    String resolved = (gqlErr?.message ?? '').trim();
    if (resolved.isEmpty) {
      resolved = (fromServerBody ?? '').trim();
    }
    if (resolved.isEmpty && link?.originalException != null) {
      resolved = link!.originalException.toString();
    }
    if (resolved.isEmpty) {
      resolved = link?.toString() ?? 'GraphQL error';
    }
    return GraphQlFailure(resolved, code: code);
  }
  return UnknownFailure(error.toString());
}
