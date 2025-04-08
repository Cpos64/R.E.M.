import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'home_screen.dart';
import 'dreams_screen.dart';
import 'sleep_log_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    });
  }

  Future<void> _saveThemePreference(bool isDarkTheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', isDarkTheme);
  }

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkTheme = value;
      _saveThemePreference(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.hasData;

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
