import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/core/config/app_config.dart';
import 'package:gdg_events/core/security/runtime_integrity.dart';
import 'package:gdg_events/core/network/graph_ql_client_provider.dart';
import 'package:gdg_events/features/auth/data/auth_repository_impl.dart';
import 'package:gdg_events/features/auth/domain/repositories/auth_repository.dart';
import 'package:gdg_events/features/events/data/events_repository_impl.dart';
import 'package:gdg_events/features/events/domain/repositories/events_repository.dart';
import 'package:gdg_events/features/profile/data/profile_repository_impl.dart';
import 'package:gdg_events/features/profile/domain/repositories/profile_repository.dart';
import 'package:gdg_events/features/registration/data/registrations_repository_impl.dart';
import 'package:gdg_events/features/registration/domain/repositories/registrations_repository.dart';
import 'package:gdg_events/features/schedule/data/schedule_repository_impl.dart';
import 'package:gdg_events/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:gdg_events/features/speakers/data/speakers_repository_impl.dart';
import 'package:gdg_events/features/speakers/domain/repositories/speakers_repository.dart';
import 'package:gdg_events/core/push/push_service.dart';
import 'package:gdg_events/features/announcements/data/announcements_repository_impl.dart';
import 'package:gdg_events/features/announcements/domain/repositories/announcements_repository.dart';

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(firebaseAuthProvider)),
);

final eventsRepositoryProvider = Provider<EventsRepository>(
  (ref) => EventsRepositoryImpl(ref.watch(graphQLClientProvider)),
);

final registrationsRepositoryProvider = Provider<RegistrationsRepository>(
  (ref) => RegistrationsRepositoryImpl(ref.watch(graphQLClientProvider)),
);

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepositoryImpl(ref.watch(graphQLClientProvider)),
);

final speakersRepositoryProvider = Provider<SpeakersRepository>(
  (ref) => SpeakersRepositoryImpl(ref.watch(graphQLClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(graphQLClientProvider)),
);

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>(
  (ref) => AnnouncementsRepositoryImpl(ref.watch(graphQLClientProvider)),
);

final pushServiceProvider = Provider<PushService>(
  (ref) => PushService(ref.watch(graphQLClientProvider)),
);

final runtimeIntegrityServiceProvider = Provider<RuntimeIntegrityService>(
  (ref) => RuntimeIntegrityService(DeviceInfoPlugin()),
);

final runtimeIntegrityProvider = FutureProvider<RuntimeIntegrityResult>(
  (ref) => ref
      .watch(runtimeIntegrityServiceProvider)
      .evaluate(enforce: AppConfig.shouldEnforceAntiTamper),
);
