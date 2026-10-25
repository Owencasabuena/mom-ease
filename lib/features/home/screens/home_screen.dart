import 'package:flutter/material.dart';
import '../../lessons/screens/lessons_screen.dart';
import '../../mood/screens/mood_tracker_screen.dart';
import '../../profile/screens/profile_screen.dart';

/// Primary shell hosting bottom navigation between Mood Tracker, Lessons, and Profile.
class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    MoodTrackerScreen(),
    LessonsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        elevation: 2,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primaryContainer,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mood_outlined),
            selectedIcon: Icon(Icons.mood_rounded),
            label: 'Mood',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Lessons',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
