import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'home_screen.dart';
import 'dreams_screen.dart';
import 'sleep_log_screen.dart';
import 'main_navigation.dart';
import 'firestore_service.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ optional font
import 'stats_screen.dart';
import 'theme/app_transitions.dart';

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

        final lightTheme = ThemeData(
          brightness: Brightness.light,
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          textTheme: GoogleFonts.latoTextTheme(), // ✅ Optional custom font
          cardTheme: CardThemeData(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );

        final darkTheme = ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme),
          cardTheme: CardThemeData(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );

        return AnimatedTheme(
          duration: const Duration(milliseconds: 300), // ✅ Smooth transition
          curve: Curves.easeInOut,
          data: _isDarkTheme ? darkTheme : lightTheme,
          child: MaterialApp(
            title: 'R.E.M',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
            home: isLoggedIn
                ? MainNavigation(
                    toggleTheme: _toggleTheme,
                    isDarkTheme: _isDarkTheme,
                  )
                : const LoginScreen(),
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/dreams':
                  return appRouteBuilder(settings, (_) => DreamsScreen());
                case '/sleep_logs':
                  return appRouteBuilder(settings, (_) => SleepLogScreen());
                case '/stats':
                  return appRouteBuilder(settings, (_) => const StatsScreen());
              }
              return null;
            },
          ),
        );
      },
    );
  }
}
