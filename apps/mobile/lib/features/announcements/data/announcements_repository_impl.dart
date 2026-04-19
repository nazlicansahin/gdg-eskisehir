import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/core/network/graph_ql_failure_mapper.dart';
import 'package:gdg_events/features/announcements/domain/entities/announcement.dart';
import 'package:gdg_events/features/announcements/domain/repositories/announcements_repository.dart';
import 'package:graphql/client.dart';

class AnnouncementsRepositoryImpl implements AnnouncementsRepository {
  AnnouncementsRepositoryImpl(this._client);

  final GraphQLClient _client;

  static const String _createMutation = r'''
mutation CreateAnnouncement($input: CreateAnnouncementInput!) {
  createAnnouncement(input: $input) {
    id eventId title body createdBy createdAt
  }
}
''';

  static const String _listByEventQuery = r'''
query Announcements($eventId: ID) {
  announcements(eventId: $eventId) {
    id eventId title body createdBy createdAt
  }
}
''';

  @override
  Future<Either<Failure, Announcement>> create({
    String? eventId,
    required String title,
    required String body,
  }) async {
    try {
      final input = <String, dynamic>{'title': title, 'body': body};
      if (eventId != null && eventId.isNotEmpty) {
        input['eventId'] = eventId;
      }
      debugPrint('[announcement] GraphQL mutate CreateAnnouncement input=$input');
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_createMutation),
          variables: {'input': input},
          fetchPolicy: FetchPolicy.noCache,
        ),
      );
      if (result.hasException) {
        debugPrint(
          '[announcement] mutate exception: ${result.exception}',
        );
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final data = result.data;
      if (data == null) {
        final gqlMsg = result.exception != null &&
                result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : null;
        debugPrint('[announcement] mutate response data=null gqlMsg=$gqlMsg');
        return Left(
          GraphQlFailure(
            gqlMsg ?? 'No data in response from server.',
          ),
        );
      }
      debugPrint('[announcement] mutate response keys=${data.keys.toList()}');
      final raw = data['createAnnouncement'];
      if (raw is! Map) {
        return Left(
          GraphQlFailure(
            raw == null
                ? 'createAnnouncement returned null (check DB migrations, permissions, or foreign keys).'
                : 'Unexpected response type: ${raw.runtimeType}',
          ),
        );
      }
      try {
        final ann = _map(Map<String, dynamic>.from(raw));
        debugPrint('[announcement] mapped announcement id=${ann.id}');
        return Right(ann);
      } on FormatException catch (e) {
        debugPrint('[announcement] map failed: $e raw=$raw');
        return Left(GraphQlFailure(e.message));
      }
    } catch (e, st) {
      debugPrint('[announcement] create unexpected: $e\n$st');
      return Left(mapGraphQlException(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Announcement>>> listByEvent(String eventId) async {
    return _list({'eventId': eventId});
  }

  @override
  Future<Either<Failure, List<Announcement>>> listAll() async {
    return _list({});
  }

  Future<Either<Failure, List<Announcement>>> _list(Map<String, dynamic> vars) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_listByEventQuery),
          variables: vars,
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final list = result.data?['announcements'] as List<dynamic>? ?? [];
      return Right(
        list
            .map((e) => _map(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  Announcement _map(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final body = json['body'];
    final createdBy = json['createdBy'];
    if (id == null || title == null || body == null || createdBy == null) {
      throw const FormatException(
        'Announcement response was missing required fields.',
      );
    }
    final createdRaw = json['createdAt'];
    final DateTime createdAt;
    if (createdRaw == null) {
      createdAt = DateTime.now().toUtc();
    } else if (createdRaw is String) {
      createdAt = DateTime.parse(createdRaw);
    } else {
      createdAt = DateTime.parse(createdRaw.toString());
    }
    return Announcement(
      id: id.toString(),
      eventId: json['eventId']?.toString(),
      title: title.toString(),
      body: body.toString(),
      createdBy: createdBy.toString(),
      createdAt: createdAt,
    );
  }
}
