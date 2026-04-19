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

  static const String _mUpdateSession = r'''
mutation UpdateSession($input: UpdateSessionInput!) {
  updateSession(input: $input) { id }
}
''';

  static const String _mUpdateSpeaker = r'''
mutation UpdateSpeaker($input: UpdateSpeakerInput!) {
  updateSpeaker(input: $input) { id }
}
''';

  static const String _mCreateSession = r'''
mutation CreateSession($input: CreateSessionInput!) {
  createSession(input: $input) { id }
}
''';

  static const String _mCreateSpeaker = r'''
mutation CreateSpeaker($input: CreateSpeakerInput!) {
  createSpeaker(input: $input) { id }
}
''';

  static const String _mAttach = r'''
mutation Attach($sessionId: ID!, $speakerId: ID!) {
  attachSpeakerToSession(sessionId: $sessionId, speakerId: $speakerId) { id }
}
''';

  @override
  Future<Either<Failure, void>> updateSession({
    required String id,
    String? title,
    String? description,
    String? room,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    try {
      final input = <String, dynamic>{'id': id};
      if (title != null) input['title'] = title;
      if (description != null) input['description'] = description;
      if (room != null) input['room'] = room;
      if (startsAt != null) input['startsAt'] = startsAt.toUtc().toIso8601String();
      if (endsAt != null) input['endsAt'] = endsAt.toUtc().toIso8601String();
      final result = await _client.mutate(
        MutationOptions(document: gql(_mUpdateSession), variables: {'input': input}),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      return const Right(null);
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  @override
  Future<Either<Failure, void>> updateSpeaker({
    required String id,
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final input = <String, dynamic>{'id': id};
      if (fullName != null) input['fullName'] = fullName;
      if (bio != null) input['bio'] = bio;
      if (avatarUrl != null) input['avatarUrl'] = avatarUrl;
      if (input.length == 1) return const Right(null);
      final result = await _client.mutate(
        MutationOptions(document: gql(_mUpdateSpeaker), variables: {'input': input}),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      return const Right(null);
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  @override
  Future<Either<Failure, String>> createSession({
    required String eventId,
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
    String? room,
  }) async {
    try {
      final input = <String, dynamic>{
        'eventId': eventId,
        'title': title,
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
      };
      if (description != null && description.isNotEmpty) input['description'] = description;
      if (room != null && room.isNotEmpty) input['room'] = room;
      final result = await _client.mutate(
        MutationOptions(document: gql(_mCreateSession), variables: {'input': input}),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final id = result.data?['createSession']?['id'] as String?;
      if (id == null) {
        return const Left(GraphQlFailure('No session id', code: 'INVALID'));
      }
      return Right(id);
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  @override
  Future<Either<Failure, String>> createSpeaker({
    required String fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final input = <String, dynamic>{'fullName': fullName};
      if (bio != null && bio.isNotEmpty) input['bio'] = bio;
      if (avatarUrl != null && avatarUrl.isNotEmpty) input['avatarUrl'] = avatarUrl;
      final result = await _client.mutate(
        MutationOptions(document: gql(_mCreateSpeaker), variables: {'input': input}),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final id = result.data?['createSpeaker']?['id'] as String?;
      if (id == null) {
        return const Left(GraphQlFailure('No speaker id', code: 'INVALID'));
      }
      return Right(id);
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  @override
  Future<Either<Failure, void>> attachSpeakerToSession({
    required String sessionId,
    required String speakerId,
  }) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_mAttach),
          variables: {'sessionId': sessionId, 'speakerId': speakerId},
        ),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      return const Right(null);
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
