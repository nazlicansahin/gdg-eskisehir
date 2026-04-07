import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/core/network/graph_ql_failure_mapper.dart';
import 'package:gdg_events/features/checkin/domain/repositories/checkin_repository.dart';
import 'package:graphql/client.dart';

class CheckInRepositoryImpl implements CheckInRepository {
  CheckInRepositoryImpl(this._client);

  final GraphQLClient _client;

  static const String _mutation = r'''
mutation CheckInByQR($eventId: ID!, $qrCode: String!) {
  checkInByQR(eventId: $eventId, qrCode: $qrCode) {
    id
    checkedInAt
  }
}
''';

  @override
  Future<Either<Failure, void>> checkInByQr({
    required String eventId,
    required String qrCode,
  }) async {
    final code = qrCode.trim();
    if (code.isEmpty) {
      return const Left(ValidationFailure('Empty QR payload'));
    }
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_mutation),
          variables: {'eventId': eventId, 'qrCode': code},
        ),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final ticket = result.data?['checkInByQR'] as Map<String, dynamic>?;
      if (ticket == null) {
        return const Left(
          GraphQlFailure('Check-in failed', code: 'INTERNAL'),
        );
      }
      return const Right(null);
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }
}
