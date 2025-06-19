import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkTheme;
  final Function(bool) toggleTheme;

  const SettingsScreen({
    super.key,
    required this.isDarkTheme,
    required this.toggleTheme,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dreamPromptEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dreamPromptEnabled = prefs.getBool('dreamPromptEnabled') ?? true;
    });
  }

  Future<void> _updateDreamPrompt(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dreamPromptEnabled', value);
    setState(() {
      _dreamPromptEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account'),
            subtitle: Text(user?.email ?? 'Unknown'),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: widget.isDarkTheme,
            onChanged: widget.toggleTheme,
            secondary: const Icon(Icons.brightness_6),
          ),
          SwitchListTile(
            title: const Text('Daily Dream Prompt'),
            subtitle: const Text('Ask "Did you dream last night?"'),
            value: _dreamPromptEnabled,
            onChanged: _updateDreamPrompt,
            secondary: const Icon(Icons.nightlight_round),
          ),
        ],
      ),
    );
  }
}
