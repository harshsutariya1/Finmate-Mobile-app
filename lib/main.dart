import 'package:finmate/services/auth_services.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/utils/routes.dart';
import 'package:finmate/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setup().then((_) {
    runApp(
      ProviderScope(child: MyApp()),
    );
  });
}

Future<void> setup() async {
  await setupFirebase();
  await registerServices();
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final AuthService _authService = GetIt.instance.get<AuthService>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: Navigate().navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      routes: Routes.routes,
      home: _authService.checkLogin(),
    );
  }
}
