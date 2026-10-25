import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mom_ease/core/services/storage_service.dart';
import 'package:mom_ease/core/theme/app_theme.dart';
import 'package:mom_ease/features/auth/models/user_model.dart';
import 'package:mom_ease/features/auth/screens/auth_screen.dart';
import 'package:mom_ease/features/auth/screens/local_setup_screen.dart';
import 'package:mom_ease/features/auth/services/auth_provider.dart';
import 'package:mom_ease/features/home/screens/home_screen.dart';
import 'package:mom_ease/features/profile/screens/profile_screen.dart';
import 'package:mom_ease/features/settings/services/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mom_ease/features/mood/models/mood_entry.dart';
import 'package:mom_ease/features/mood/models/mood_type.dart';
import 'package:mom_ease/features/mood/repositories/mood_repository.dart';
import 'package:mom_ease/features/mood/services/mood_service.dart';
import 'package:mom_ease/features/mood/state/mood_provider.dart';
import 'package:mom_ease/features/mood/widgets/calendar_view.dart';
import 'package:mom_ease/features/mood/widgets/log_mood_bottom_sheet.dart';
import 'package:mom_ease/features/mood/widgets/mood_statistics.dart';

class _FakeMoodRepository implements MoodRepository {
  final Map<String, MoodEntry> _entries = {};

  @override
  Future<void> deleteMood(String userId, DateTime date) async {
    _entries.remove('${userId}_${date.year}_${date.month}_${date.day}');
  }

  @override
  Future<Map<MoodType, int>> getMoodCountsForMonth(
      String userId, int year, int month) async {
    final list = await getMoodsForMonth(userId, year, month);
    final map = {for (final m in MoodType.values) m: 0};
    for (final e in list) {
      map[e.mood] = (map[e.mood] ?? 0) + 1;
    }
    return map;
  }

  @override
  Future<MoodEntry?> getMoodForDate(String userId, DateTime date) async {
    return _entries['${userId}_${date.year}_${date.month}_${date.day}'];
  }

  @override
  Future<List<MoodEntry>> getMoodsForMonth(
      String userId, int year, int month) async {
    return _entries.values
        .where((e) =>
            e.userId == userId &&
            e.date.year == year &&
            e.date.month == month)
        .toList();
  }

  @override
  Future<List<MoodEntry>> getRecentMoods(String userId, {int days = 7}) async {
    return _entries.values.where((e) => e.userId == userId).toList();
  }

  @override
  Future<bool> hasMoodForDate(String userId, DateTime date) async {
    return _entries.containsKey('${userId}_${date.year}_${date.month}_${date.day}');
  }

  @override
  Future<void> saveMood(MoodEntry entry) async {
    _entries['${entry.userId}_${entry.date.year}_${entry.date.month}_${entry.date.day}'] =
        entry;
  }

  @override
  Future<void> updateMood(MoodEntry entry) async {
    _entries['${entry.userId}_${entry.date.year}_${entry.date.month}_${entry.date.day}'] =
        entry;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MomEase Auth & Profile Widget Tests', () {
    late StorageService storageService;
    late AuthProvider authProvider;
    late ThemeProvider themeProvider;
    late MoodProvider moodProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs);
      authProvider = AuthProvider(storageService);
      themeProvider = ThemeProvider(storageService);
      moodProvider = MoodProvider(MoodService(_FakeMoodRepository()), 'test_user');
      await authProvider.initialize();
    });

    Widget createTestWidget(Widget child) {
      return MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storageService),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<MoodProvider>.value(value: moodProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: child,
        ),
      );
    }

    testWidgets('AuthScreen displays welcoming header, options, and privacy notice',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const AuthScreen()));
      await tester.pumpAndSettle();

      // Check header and tagline
      expect(find.text('MomEase'), findsOneWidget);
      expect(
        find.text('Support for every step of your postpartum journey.'),
        findsOneWidget,
      );

      // Check authentication buttons
      expect(find.byKey(const Key('continue_with_google_btn')), findsOneWidget);
      expect(find.byKey(const Key('continue_locally_btn')), findsOneWidget);

      // Check privacy guarantee
      expect(
        find.text('Using MomEase locally keeps your personal entries on this device.'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping Continue with Google when unconfigured shows friendly notice',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const AuthScreen()));
      await tester.pumpAndSettle();

      // Tap Google sign in
      await tester.tap(find.byKey(const Key('continue_with_google_btn')));
      await tester.pumpAndSettle();

      // Verify friendly dialog
      expect(find.text('Google Sign-In Notice'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Continue Locally'), findsOneWidget);
    });

    testWidgets('Local setup screen validates input and registers local mama',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const LocalSetupScreen()));
      await tester.pumpAndSettle();

      // Try submitting empty
      await tester.tap(find.byKey(const Key('submit_local_setup_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your name or preferred nickname'), findsOneWidget);

      // Enter valid name
      await tester.enterText(find.byKey(const Key('name_input_field')), 'Sarah');
      await tester.tap(find.byKey(const Key('submit_local_setup_btn')));
      await tester.pumpAndSettle();

      // Ensure user is registered and authenticated
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.displayName, equals('Sarah'));
      expect(authProvider.currentUser?.isLocal, isTrue);
    });

    testWidgets('HomeScreen displays maternal greeting and profile navigation icon',
        (WidgetTester tester) async {
      await authProvider.continueLocally(displayName: 'Elena');

      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Elena'), findsOneWidget);
      expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);

      // Verify Mood Tracker home features
      expect(find.text('Log Your Mood'), findsOneWidget);
      expect(find.text('Suggested for you'), findsOneWidget);
    });

    testWidgets('ProfileScreen shows local account info and options',
        (WidgetTester tester) async {
      await authProvider.continueLocally(displayName: 'Hannah');

      await tester.pumpWidget(createTestWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Hannah'), findsOneWidget);
      expect(find.text('Local Account'), findsOneWidget);
      expect(find.text('Change Username'), findsOneWidget);
      expect(find.text('Change Local Password / PIN'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Delete Local Account'), findsOneWidget);
    });

    test('UserModel serialization and local/google flags work as expected', () {
      final localUser = UserModel(
        id: 'test_123',
        displayName: 'Sarah',
        authType: AuthType.local,
        createdAt: DateTime(2026, 1, 1),
        hasPin: true,
      );

      expect(localUser.isLocal, isTrue);
      expect(localUser.isGoogle, isFalse);

      final map = localUser.toMap();
      final restored = UserModel.fromMap(map);

      expect(restored.id, equals('test_123'));
      expect(restored.displayName, equals('Sarah'));
      expect(restored.authType, equals(AuthType.local));
      expect(restored.hasPin, isTrue);
    });

    test('Theme switching updates themeMode and persists', () async {
      expect(themeProvider.themeMode, equals(ThemeMode.system));

      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.themeMode, equals(ThemeMode.dark));
      expect(storageService.getThemeMode(), equals(ThemeMode.dark));

      await themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.themeMode, equals(ThemeMode.light));
      expect(storageService.getThemeMode(), equals(ThemeMode.light));
    });

    testWidgets(
        'LogMoodBottomSheet renders without overflow on narrow screens',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => showLogMoodSheet(ctx),
          child: const Text('Open Sheet'),
        ),
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('How are you feeling?'), findsOneWidget);
      expect(find.text('Very Happy'), findsOneWidget);
      expect(find.text('Very Sad'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'MoodStatistics renders Monthly Summary and semicircle chart without overflow',
        (WidgetTester tester) async {
      // Save 5 entries
      final now = DateTime.now();
      await moodProvider.saveMoodForSelectedDate(MoodType.verySad);
      await moodProvider.selectDate(now.subtract(const Duration(days: 1)));
      await moodProvider.saveMoodForSelectedDate(MoodType.verySad);
      await moodProvider.selectDate(now.subtract(const Duration(days: 2)));
      await moodProvider.saveMoodForSelectedDate(MoodType.verySad);
      await moodProvider.selectDate(now.subtract(const Duration(days: 3)));
      await moodProvider.saveMoodForSelectedDate(MoodType.neutral);
      await moodProvider.selectDate(now.subtract(const Duration(days: 4)));
      await moodProvider.saveMoodForSelectedDate(MoodType.happy);

      await tester.pumpWidget(createTestWidget(const SingleChildScrollView(
        child: MoodStatistics(),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Monthly Summary'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('5 check-ins this month'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CalendarView expands and switches to Summary tab cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const SingleChildScrollView(
        child: CalendarView(),
      )));
      await tester.pumpAndSettle();

      // Tap header to expand
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Check SegmentedButton appears with Calendar and Summary
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);

      // Tap Summary tab
      await tester.tap(find.text('Summary'));
      await tester.pumpAndSettle();

      // Summary view displays
      expect(find.text('No mood check-ins yet this month.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

