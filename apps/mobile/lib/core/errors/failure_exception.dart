import 'package:gdg_events/core/errors/failures.dart';

/// Bridges [Failure] into async error channels (e.g. [AsyncValue.error]).
class FailureException implements Exception {
  FailureException(this.failure);

  final Failure failure;

  @override
  String toString() => failure.toString();
}
