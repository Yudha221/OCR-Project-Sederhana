import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../pages/auth/login_page.dart';
import '../pages/home/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();

    return FutureBuilder<bool>(
      future: authController.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}
