import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/core/network/graph_ql_failure_mapper.dart';
import 'package:gdg_events/features/schedule/domain/entities/schedule_session.dart';
import 'package:gdg_events/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:gdg_events/features/speakers/domain/entities/speaker.dart';
import 'package:graphql/client.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl(this._client);

  final GraphQLClient _client;

  static const String _qSchedule = r'''
query EventSchedule($eventId: ID!) {
  eventSchedule(eventId: $eventId) {
    id
    eventId
    title
    description
    startsAt
    endsAt
    room
    speakers {
      id
      fullName
      bio
      avatarUrl
    }
  }
}
''';

  @override
  Future<Either<Failure, List<ScheduleSession>>> listByEvent(
    String eventId,
  ) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_qSchedule),
          variables: {'eventId': eventId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final rows = result.data?['eventSchedule'] as List<dynamic>? ?? [];
      return Right(rows.map((e) => _map(e as Map<String, dynamic>)).toList());
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  ScheduleSession _map(Map<String, dynamic> json) {
    final speakers = (json['speakers'] as List<dynamic>? ?? [])
        .map(
          (s) => Speaker(
            id: s['id'] as String,
            fullName: s['fullName'] as String,
            bio: s['bio'] as String?,
            avatarUrl: s['avatarUrl'] as String?,
          ),
        )
        .toList();

    return ScheduleSession(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      room: json['room'] as String?,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      speakers: speakers,
    );
  }
}
