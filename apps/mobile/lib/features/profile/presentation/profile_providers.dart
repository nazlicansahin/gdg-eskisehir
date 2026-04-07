import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/app/providers.dart';
import 'package:gdg_events/core/errors/failure_exception.dart';
import 'package:gdg_events/features/profile/domain/entities/profile_user.dart';

final profileProvider = FutureProvider.autoDispose<ProfileUser>((ref) async {
  final result = await ref.watch(profileRepositoryProvider).me();
  return result.fold(
    (f) => throw FailureException(f),
    (u) => u,
  );
});
