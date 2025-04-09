import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'home_screen.dart';
import 'dreams_screen.dart';
import 'sleep_log_screen.dart';
import 'firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = false;
  bool _themeLoaded = false; // ✅ Prevent loading multiple times
  final FirestoreService _firestoreService = FirestoreService();

  // ✅ Load user-specific theme from Firestore
  Future<void> _loadThemePreference() async {
    final theme = await _firestoreService.loadUserTheme();
    setState(() {
      _isDarkTheme = theme;
    });
  }

  // ✅ Save user-specific theme to Firestore
  Future<void> _saveThemePreference(bool isDarkTheme) async {
    await _firestoreService.saveUserTheme(isDarkTheme);
  }

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkTheme = value;
    });
    _saveThemePreference(value);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isLoggedIn = user != null;

        // ✅ Load theme only once when user is confirmed
        if (isLoggedIn && !_themeLoaded) {
          _loadThemePreference();
          _themeLoaded = true;
        }

        // 🔁 Reset on logout
        if (!isLoggedIn && _themeLoaded) {
          _themeLoaded = false;
        }

        return MaterialApp(
          title: 'R.E.M',
          theme: _isDarkTheme ? ThemeData.dark() : ThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: isLoggedIn
              ? HomeScreen(
                  toggleTheme: _toggleTheme,
                  isDarkTheme: _isDarkTheme,
                )
              : const LoginScreen(),
          routes: {
            '/dreams': (context) => DreamsScreen(),
            '/sleep_logs': (context) => SleepLogScreen(),
          },
        );
      },
    );
  }
}
