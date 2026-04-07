import 'package:equatable/equatable.dart';

/// Domain-facing error (mapped from API / GraphQL).
sealed class Failure extends Equatable {
  const Failure();

  @override
  List<Object?> get props => [];
}

class UnknownFailure extends Failure {
  const UnknownFailure([this.message = 'Something went wrong']);

  final String message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([this.message = 'Network error']);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends Failure {
  const AuthFailure([this.message = 'Not signed in']);

  final String message;

  @override
  List<Object?> get props => [message];
}

class GraphQlFailure extends Failure {
  const GraphQlFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

class ValidationFailure extends Failure {
  const ValidationFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

extension FailureUserMessage on Failure {
  String get asUserMessage => switch (this) {
        GraphQlFailure(:final message) => message,
        AuthFailure(:final message) => message,
        NetworkFailure(:final message) => message,
        ValidationFailure(:final message) => message,
        UnknownFailure(:final message) => message,
      };
}
