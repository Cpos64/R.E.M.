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
      const SnackBar(content: Text('Logged out successfully')),
    );
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('R.E.M. Home'),
        actions: [
          IconButton(
            icon: Icon(isDarkTheme ? Icons.nights_stay : Icons.wb_sunny),
            tooltip: 'Toggle theme',
            onPressed: () => toggleTheme(!isDarkTheme),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Welcome to R.E.M!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Version A: full-width buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.book),
                label: const Text('Dream Journal'),
                onPressed: () => Navigator.pushNamed(context, '/dreams'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bedtime),
                label: const Text('Sleep Logs'),
                onPressed: () => Navigator.pushNamed(context, '/sleep_logs'),
              ),
            ),

            const Divider(height: 40),

            // Version B: ListTiles (alternative)
            // ListTile(
            //   leading: const Icon(Icons.book),
            //   title: const Text('Dream Journal'),
            //   onTap: () => Navigator.pushNamed(context, '/dreams'),
            // ),
            // ListTile(
            //   leading: const Icon(Icons.bedtime),
            //   title: const Text('Sleep Logs'),
            //   onTap: () => Navigator.pushNamed(context, '/sleep_logs'),
            // ),
          ],
        ),
      ),
    );
  }
}
