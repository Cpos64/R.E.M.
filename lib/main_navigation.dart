import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'sleep_log_screen.dart';
import 'dreams_screen.dart';
import 'social_screen.dart';
import 'chat_sleept_screen.dart';

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
      const SocialScreen(),
      const ChatSleeptScreen(),
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
        items: const [
          BottomNavigationBarItem(icon: Text('🏠', style: TextStyle(fontSize: 24)), label: 'Home'),
          BottomNavigationBarItem(icon: Text('🛏️', style: TextStyle(fontSize: 24)), label: 'Sleep'),
          BottomNavigationBarItem(icon: Text('💭', style: TextStyle(fontSize: 24)), label: 'Dream'),
          BottomNavigationBarItem(icon: Text('👥', style: TextStyle(fontSize: 24)), label: 'Social'),
          BottomNavigationBarItem(icon: Text('🤖', style: TextStyle(fontSize: 24)), label: 'ChatSLEEPT'),
        ],
      ),
    );
  }
}
