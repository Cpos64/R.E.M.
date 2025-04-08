import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Function(bool) toggleTheme;
  final bool isDarkTheme;

  // ✅ Corrected Constructor Declaration
  const HomeScreen({
    required this.toggleTheme,
    required this.isDarkTheme,
    Key? key,
  }) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await _auth.signOut();
    await prefs.remove('email');
    await prefs.remove('password');
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AuthScreen(
          toggleTheme: toggleTheme, // Pass toggleTheme to AuthScreen
          isDarkTheme: isDarkTheme, // Pass current theme state to AuthScreen
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home - R.E.M.'),
        actions: [
          Row(
            children: [
              Text('Dark Mode', style: TextStyle(fontSize: 16)),
              Switch(
                value: isDarkTheme,
                onChanged: (value) {
                  toggleTheme(value);
                },
              ),
              IconButton(
                icon: Icon(Icons.logout),
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
