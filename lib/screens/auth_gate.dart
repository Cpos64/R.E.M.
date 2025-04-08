import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../home_screen.dart';

class AuthGate extends StatelessWidget {
  final Function(bool) toggleTheme;
  final bool isDarkTheme;

  const AuthGate({
    super.key,
    required this.toggleTheme,
    required this.isDarkTheme,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return HomeScreen(
            toggleTheme: toggleTheme,
            isDarkTheme: isDarkTheme,
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
