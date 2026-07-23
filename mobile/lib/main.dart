import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/environment.dart';
import 'data/api_client.dart';
import 'data/repositories.dart';
import 'data/session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SessionStorage();
  final api = ApiClient(
    baseUrl: Environment.apiBaseUrl,
    storage: storage,
  );
  final auth = AuthRepository(api: api, storage: storage);
  final academic = AcademicRepository(api: api);
  final advisor = AdvisorRepository(api: api);

  await auth.restoreSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: academic),
        ChangeNotifierProvider.value(value: advisor),
      ],
      child: const DegreeLensApp(),
    ),
  );
}
