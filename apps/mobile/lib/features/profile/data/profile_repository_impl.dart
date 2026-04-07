import 'package:fpdart/fpdart.dart';
import 'package:gdg_events/core/errors/failures.dart';
import 'package:gdg_events/core/network/graph_ql_failure_mapper.dart';
import 'package:gdg_events/features/profile/domain/entities/profile_user.dart';
import 'package:gdg_events/features/profile/domain/repositories/profile_repository.dart';
import 'package:graphql/client.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._client);

  final GraphQLClient _client;

  static const String _qMe = r'''
query Me {
  me {
    id
    email
    displayName
    roles
  }
}
''';

  static const String _mUpdate = r'''
mutation UpdateMyProfile($displayName: String!) {
  updateMyProfile(input: { displayName: $displayName }) {
    id
    email
    displayName
    roles
  }
}
''';

  @override
  Future<Either<Failure, ProfileUser>> me() async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(_qMe),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final raw = result.data?['me'] as Map<String, dynamic>?;
      if (raw == null) {
        return const Left(
          GraphQlFailure('Profile not found', code: 'NOT_FOUND'),
        );
      }
      return Right(_map(raw));
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  @override
  Future<Either<Failure, ProfileUser>> updateMyProfile({
    required String displayName,
  }) async {
    final name = displayName.trim();
    if (name.isEmpty) {
      return const Left(ValidationFailure('Display name cannot be empty'));
    }
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(_mUpdate),
          variables: {'displayName': name},
        ),
      );
      if (result.hasException) {
        return Left(mapGraphQlException(result.exception!, StackTrace.current));
      }
      final raw = result.data?['updateMyProfile'] as Map<String, dynamic>?;
      if (raw == null) {
        return const Left(
          GraphQlFailure('Profile update failed', code: 'INTERNAL'),
        );
      }
      return Right(_map(raw));
    } catch (e, st) {
      return Left(mapGraphQlException(e, st));
    }
  }

  ProfileUser _map(Map<String, dynamic> json) {
    final rolesRaw = json['roles'] as List<dynamic>? ?? const [];
    return ProfileUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      roles: rolesRaw.map((e) => e as String).toList(),
    );
  }
}
