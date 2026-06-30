import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/health_sync_service.dart';

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
  bool _healthSyncEnabled = false;
  bool _healthSyncBusy = false;
  final HealthSyncService _healthSyncService = HealthSyncService();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dreamPromptEnabled = prefs.getBool('dreamPromptEnabled') ?? true;
      _healthSyncEnabled = prefs.getBool('healthSyncEnabled') ?? false;
    });
  }

  Future<void> _updateDreamPrompt(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dreamPromptEnabled', value);
    setState(() {
      _dreamPromptEnabled = value;
    });
  }

  Future<void> _updateHealthSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('healthSyncEnabled', value);
    setState(() {
      _healthSyncEnabled = value;
    });

    if (!value) return;

    setState(() => _healthSyncBusy = true);
    final result = await _healthSyncService.requestAuthorizationAndInitialSync();
    if (!mounted) return;
    setState(() => _healthSyncBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> _syncNow() async {
    setState(() => _healthSyncBusy = true);
    final result = await _healthSyncService.syncRecentDays(days: 7);
    if (!mounted) return;
    setState(() => _healthSyncBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
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
          SwitchListTile(
            title: const Text('Sync with Health App'),
            subtitle: const Text('Import sleep data from Apple Health / Health Connect'),
            value: _healthSyncEnabled,
            onChanged: _healthSyncBusy ? null : _updateHealthSync,
            secondary: const Icon(Icons.favorite),
          ),
          if (_healthSyncEnabled)
            ListTile(
              leading: _healthSyncBusy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              title: const Text('Sync Now'),
              onTap: _healthSyncBusy ? null : _syncNow,
            ),
        ],
      ),
    );
  }
}
