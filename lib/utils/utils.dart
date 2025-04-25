import 'package:finmate/services/upi_payment_service.dart';
import 'package:finmate/utils/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:finmate/services/auth_services.dart';

Future<void> setupFirebase() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Firebase.initializeApp();
  print('__Firebase app is initialized!__');
}

Future<void> registerServices() async {
  final GetIt getIt = GetIt.instance;
  getIt.registerSingleton<AuthService>(AuthService());
  getIt.registerSingleton<UpiPaymentService>(UpiPaymentService());
}

Future<void> getApiKeys() async {
  await dotenv.load(fileName: ".env"); // Load the .env file
}