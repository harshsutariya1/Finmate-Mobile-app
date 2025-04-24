import 'package:finmate/screens/auth/auth_check_widget.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finmate/screens/home/market screens/market_overview_screen.dart';
import 'package:finmate/screens/home/market screens/market_detail_screen.dart';
import 'package:finmate/models/market_data.dart';
import 'package:finmate/services/market_api_service.dart';
import 'package:finmate/providers/market_provider.dart';

void main() {
  setup().then((_) {
    runApp(
      ProviderScope(
        child: MyApp(),
      ),
    );
  });
}

Future<void> setup() async {
  await setupFirebase();
  await registerServices();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      navigatorKey: Navigate().navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: AuthCheckWidget(),
    );
  }
}
