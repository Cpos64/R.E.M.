import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'sleep_log_screen.dart';
import 'dreams_screen.dart';
import 'groups_screen.dart';
import 'me_screen.dart';

class MainNavigation extends StatefulWidget {
  final Function(bool) toggleTheme;
  final bool isDarkTheme;

  const MainNavigation({
    super.key,
    required this.toggleTheme,
    required this.isDarkTheme,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(toggleTheme: widget.toggleTheme, isDarkTheme: widget.isDarkTheme),
      const SleepLogScreen(),
      const DreamsScreen(),
      const GroupsScreen(),
      const MeScreen(),
    ];
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hotel),
            label: 'Sleep',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Dreams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'You',
          ),
        ],
      ),
    );
  }
}
