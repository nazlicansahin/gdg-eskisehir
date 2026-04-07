import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/core/network/graph_ql_failure_mapper.dart';
import 'package:gdg_events/features/events/domain/entities/event.dart';
import 'package:gdg_events/features/events/domain/event_status.dart';
import 'package:gdg_events/features/events/domain/repositories/events_repository.dart';
import 'package:graphql/client.dart';

class EventsRepositoryImpl implements EventsRepository {
  EventsRepositoryImpl(this._client);

  final GraphQLClient _client;

  static const String _queryList = r'''
query UserEvents {
  events {
    id
    title
    description
    status
    capacity
    startsAt
    endsAt
  }
}
''';

  static const String _queryOne = r'''
query UserEvent($id: ID!) {
  event(id: $id) {
    id
    title
    description
    status
    capacity
    startsAt
    endsAt
  }
}
''';

  @override
  Future<Either<Failure, List<Event>>> listPublished() async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_queryList),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final list = result.data?['events'] as List<dynamic>? ?? [];
      return Right(
        list.map((e) => _mapEvent(e as Map<String, dynamic>)).toList(),
      );
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  @override
  Future<Either<Failure, Event>> getPublished(String id) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_queryOne),
          variables: {'id': id},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final raw = result.data?['event'];
      if (raw == null) {
        return const Left(GraphQlFailure('Event not found', code: 'NOT_FOUND'));
      }
      return Right(_mapEvent(raw as Map<String, dynamic>));
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  Event _mapEvent(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: EventStatus.fromJson(json['status'] as String),
      capacity: (json['capacity'] as num).toInt(),
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
    );
  }
}
