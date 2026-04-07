import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/core/network/graph_ql_failure_mapper.dart';
import 'package:gdg_events/features/registration/domain/entities/registration_ticket.dart';
import 'package:gdg_events/features/registration/domain/registration_status.dart';
import 'package:gdg_events/features/registration/domain/repositories/registrations_repository.dart';
import 'package:graphql/client.dart';

class RegistrationsRepositoryImpl implements RegistrationsRepository {
  RegistrationsRepositoryImpl(this._client);

  final GraphQLClient _client;

  @override
  Future<Either<Failure, List<RegistrationTicket>>> myRegistrations() async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_qRegs),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final list = result.data?['myRegistrations'] as List<dynamic>? ?? [];
      return Right(
        list.map((e) => _mapTicket(e as Map<String, dynamic>)).toList(),
      );
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  static const String _qRegs = r'''
query MyRegistrations {
  myRegistrations {
    id
    eventId
    userId
    status
    qrCodeValue
    checkedInAt
  }
}
''';

  static const String _mutRegister = r'''
mutation Register($eventId: ID!) {
  registerForEvent(eventId: $eventId) {
    id
    eventId
    userId
    status
    qrCodeValue
    checkedInAt
  }
}
''';

  static const String _qTicket = r'''
query MyTicket($eventId: ID!) {
  myTicket(eventId: $eventId) {
    id
    eventId
    userId
    status
    qrCodeValue
    checkedInAt
  }
}
''';

  @override
  Future<Either<Failure, RegistrationTicket>> registerForEvent(
    String eventId,
  ) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_mutRegister),
          variables: {'eventId': eventId},
        ),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final raw = result.data?['registerForEvent'] as Map<String, dynamic>?;
      if (raw == null) {
        return const Left(UnknownFailure('Empty registration response'));
      }
      return Right(_mapTicket(raw));
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  @override
  Future<Either<Failure, RegistrationTicket?>> myTicket(String eventId) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_qTicket),
          variables: {'eventId': eventId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final raw = result.data?['myTicket'];
      if (raw == null) {
        return const Right(null);
      }
      return Right(_mapTicket(raw as Map<String, dynamic>));
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  RegistrationTicket _mapTicket(Map<String, dynamic> json) {
    return RegistrationTicket(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      status: RegistrationStatus.fromJson(json['status'] as String),
      qrCodeValue: json['qrCodeValue'] as String,
      checkedInAt: json['checkedInAt'] == null
          ? null
          : DateTime.parse(json['checkedInAt'] as String),
    );
  }
}
