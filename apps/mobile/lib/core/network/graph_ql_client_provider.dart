import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_events/core/config/app_config.dart';
import 'package:graphql/client.dart';

/// Fresh GraphQL client: Firebase ID token is attached on every request.
final graphQLClientProvider = Provider<GraphQLClient>((ref) {
  final link = Link.from([
    AuthLink(
      getToken: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return null;
        final token = await user.getIdToken();
        if (token == null || token.isEmpty) return null;
        return 'Bearer $token';
      },
    ),
    HttpLink(AppConfig.graphqlUri.toString()),
  ]);

  return GraphQLClient(
    link: link,
    cache: GraphQLCache(store: InMemoryStore()),
  );
});
