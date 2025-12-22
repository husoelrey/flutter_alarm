import 'package:alarm/presentation/screens/alarm_home_page.dart';
import 'package:flutter/material.dart';

import '../../screens/awareness_page.dart';
import '../../screens/motivation_page.dart';

/// The main shell of the application which holds the bottom navigation bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // The pages that correspond to the bottom navigation bar items
  final List<Widget> _pages = [
    const AlarmHomePage(),
    MotivationPage(),
    AwarenessPage(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_alarm),
            label: 'Alarms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_quote),
            label: 'Motivation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Awareness',
          ),
        ],
      ),
    );
  }
}
