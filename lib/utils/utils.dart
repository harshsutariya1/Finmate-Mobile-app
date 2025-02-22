import 'package:finmate/utils/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:finmate/services/auth_services.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

Future<void> setupFirebase() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ShorebirdUpdater().update();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Firebase.initializeApp();
  print('__Firebase app is initialized!__');
}

Future<void> registerServices() async {
  final GetIt getIt = GetIt.instance;
  getIt.registerSingleton<AuthService>(AuthService());
}
