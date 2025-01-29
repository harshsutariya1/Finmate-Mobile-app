import 'package:finmate/services/auth_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late AuthService _authService;
  @override
  void initState() {
    _authService = GetIt.instance.get<AuthService>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        leading: IconButton(
          onPressed: () async {
            if (await _authService.logout()) {
              Navigator.pushNamed(context, '/auth');
              snackbarToast(
                context: context,
                text: "Logout successful",
                icon: Icons.done_all_outlined,
              );
            } else {
              snackbarToast(
                context: context,
                text: "Error logging out",
                icon: Icons.error_rounded,
              );
            }
          },
          icon: Icon(Icons.logout_outlined),
        ),
      ),
      body: Center(
        child: Text("FinMate App Home"),
      ),
    );
  }
}
