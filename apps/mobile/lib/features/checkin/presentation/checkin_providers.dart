import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/core/network/graph_ql_client_provider.dart';
import 'package:gdg_events/features/checkin/data/checkin_repository_impl.dart';
import 'package:gdg_events/features/checkin/domain/repositories/checkin_repository.dart';

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepositoryImpl(ref.watch(graphQLClientProvider));
});
