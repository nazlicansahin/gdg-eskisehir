import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/core/config/app_config.dart';
import 'package:graphql/client.dart';

/// GraphQL client: attaches Firebase ID token on each request.
///
/// Do not call [FirebaseAuth.signOut] from a GraphQL [ErrorLink] here: a single
/// operations.failure with `UNAUTHENTICATED` would log the user out even when
/// Firebase still has a valid session (e.g. transient backend or ordering issues).
/// [GoRouter] already sends users to `/login` when [currentUser] is null.
final graphQLClientProvider = Provider<GraphQLClient>((ref) {
  final link = Link.from([
    AuthLink(
      getToken: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return null;
        }
        var token = await user.getIdToken();
        if (token == null || token.isEmpty) {
          token = await user.getIdToken(true);
        }
        if (token == null || token.isEmpty) {
          return null;
        }
        return 'Bearer $token';
      },
    ),
    HttpLink(AppConfig.graphqlUri.toString()),
  ]);

  return GraphQLClient(
    link: link,
    cache: GraphQLCache(store: InMemoryStore()),
    queryRequestTimeout: const Duration(seconds: 20),
  );
});
