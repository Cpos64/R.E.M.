import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Function(bool) toggleTheme;
  final bool isDarkTheme;

  const HomeScreen({
    required this.toggleTheme,
    required this.isDarkTheme,
    super.key,
  });

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await _auth.signOut();
    await prefs.remove('email');
    await prefs.remove('password');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged out successfully')),
    );

    // 🔄 Small delay to let authStateChanges trigger rebuild in main.dart
    await Future.delayed(Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('R.E.M. Home'),
        actions: [
          Row(
            children: [
              Icon(Icons.dark_mode),
              Switch(
                value: isDarkTheme,
                onChanged: toggleTheme,
              ),
              IconButton(
                icon: Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () => _logout(context),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to R.E.M!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/dreams');
              },
              child: Text('Go to Dream Journal'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/sleep_logs');
              },
              child: Text('Go to Sleep Logs'),
            ),
          ],
        ),
      ),
    );
  }
}
