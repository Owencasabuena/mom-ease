import 'package:flutter/material.dart';
import '../../mood/screens/mood_tracker_screen.dart';

/// Primary home screen — hosts the Mood Tracker as the main experience.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MoodTrackerScreen();
  }
}
