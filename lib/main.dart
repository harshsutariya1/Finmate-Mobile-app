import 'package:finmate/services/auth_services.dart';
import 'package:finmate/utils/routes.dart';
import 'package:finmate/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      routes: Routes.routes,
      home: _authService.checkLogin(),
    );
  }
}
