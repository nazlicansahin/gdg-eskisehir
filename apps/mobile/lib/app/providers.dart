import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/core/network/graph_ql_client_provider.dart';
import 'package:gdg_events/features/auth/data/auth_repository_impl.dart';
import 'package:gdg_events/features/auth/domain/repositories/auth_repository.dart';
import 'package:gdg_events/features/events/data/events_repository_impl.dart';
import 'package:gdg_events/features/events/domain/repositories/events_repository.dart';
import 'package:gdg_events/features/registration/data/registrations_repository_impl.dart';
import 'package:gdg_events/features/registration/domain/repositories/registrations_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(firebaseAuthProvider)),
);

final eventsRepositoryProvider = Provider<EventsRepository>(
  (ref) => EventsRepositoryImpl(ref.watch(graphQLClientProvider)),
);

final registrationsRepositoryProvider = Provider<RegistrationsRepository>(
  (ref) => RegistrationsRepositoryImpl(ref.watch(graphQLClientProvider)),
);
