import 'package:flutter/material.dart';
import 'calendar_view.dart';

/// Legacy alias for [CalendarView].
/// The date selector and expandable calendar have been unified into [CalendarView].
class DateSelector extends StatelessWidget {
  const DateSelector({super.key});

  @override
  Widget build(BuildContext context) => const CalendarView();
}
