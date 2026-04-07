import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/core/network/graph_ql_failure_mapper.dart';
import 'package:gdg_events/features/speakers/domain/entities/speaker.dart';
import 'package:gdg_events/features/speakers/domain/repositories/speakers_repository.dart';
import 'package:graphql/client.dart';

class SpeakersRepositoryImpl implements SpeakersRepository {
  SpeakersRepositoryImpl(this._client);

  final GraphQLClient _client;

  static const String _qSpeakers = r'''
query Speakers($query: String) {
  speakers(filter: { query: $query }) {
    id
    fullName
    bio
    avatarUrl
  }
}
''';

  static const String _qSpeaker = r'''
query Speaker($id: ID!) {
  speaker(id: $id) {
    id
    fullName
    bio
    avatarUrl
  }
}
''';

  @override
  Future<Either<Failure, List<Speaker>>> list({String? query}) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_qSpeakers),
          variables: {'query': query},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final rows = result.data?['speakers'] as List<dynamic>? ?? [];
      return Right(rows.map((e) => _map(e as Map<String, dynamic>)).toList());
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  @override
  Future<Either<Failure, Speaker>> getByID(String id) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_qSpeaker),
          variables: {'id': id},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final raw = result.data?['speaker'];
      if (raw == null) {
        return const Left(
          GraphQlFailure('Speaker not found', code: 'NOT_FOUND'),
        );
      }
      return Right(_map(raw as Map<String, dynamic>));
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  Speaker _map(Map<String, dynamic> json) {
    return Speaker(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
