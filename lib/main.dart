import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/services/auth_provider.dart';
import 'features/journal/data/local_journal_repository.dart';
import 'features/journal/models/journal_entry.dart';
import 'features/journal/providers/journal_provider.dart';
import 'features/journal/services/journal_service.dart';
import 'features/lessons/data/local_lesson_repository.dart';
import 'features/lessons/providers/lesson_provider.dart';
import 'features/lessons/services/lesson_service.dart';
import 'features/mood/models/mood_entry.dart';
import 'features/mood/models/mood_type.dart';
import 'features/mood/repositories/local_mood_repository.dart';
import 'features/mood/services/mood_service.dart';
import 'features/mood/state/mood_provider.dart';
import 'features/settings/services/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (fail-safe so local/offline mode is never blocked)
  bool isFirebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseReady = true;
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize Hive local database
  await Hive.initFlutter();
  Hive.registerAdapter<MoodEntry>(MoodEntryAdapter());
  Hive.registerAdapter<MoodType>(MoodTypeAdapter());
  Hive.registerAdapter<JournalEntry>(JournalEntryAdapter());
  await Hive.openBox<MoodEntry>('moodBox');
  await Hive.openBox<JournalEntry>('journalBox');

  // Initialize persistent storage (SharedPreferences + FlutterSecureStorage)
  final storageService = await StorageService.initialize();

  // Initialize auth & theme providers
  final authProvider =
      AuthProvider(storageService, isFirebaseReady: isFirebaseReady);
  final themeProvider = ThemeProvider(storageService);

  // Hydrate auth state prior to UI render
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        // MoodProvider is created lazily per authenticated user.
        // It reads the userId from AuthProvider at creation time.
        ChangeNotifierProxyProvider<AuthProvider, MoodProvider>(
          create: (_) => MoodProvider(
            MoodService(LocalMoodRepository()),
            authProvider.currentUser?.id ?? 'local_user',
          ),
          update: (_, auth, previous) {
            final userId = auth.currentUser?.id ?? 'local_user';
            if (previous != null && previous.userId == userId) {
              return previous;
            }
            return MoodProvider(
              MoodService(LocalMoodRepository()),
              userId,
            );
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, LessonProvider>(
          create: (_) => LessonProvider(
            LessonService(
              LocalLessonRepository(),
              authProvider.currentUser?.id ?? 'local_user',
            ),
          ),
          update: (_, auth, previous) {
            if (previous != null) {
              return previous;
            }
            final userId = auth.currentUser?.id ?? 'local_user';
            return LessonProvider(
              LessonService(
                LocalLessonRepository(),
                userId,
              ),
            );
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, JournalProvider>(
          create: (_) => JournalProvider(
            JournalService(
              LocalJournalRepository(),
              authProvider.currentUser?.id ?? 'local_user',
              storageService,
            ),
          ),
          update: (_, auth, previous) {
            final userId = auth.currentUser?.id ?? 'local_user';
            if (previous != null && previous.userId == userId) {
              return previous;
            }
            return JournalProvider(
              JournalService(
                LocalJournalRepository(),
                userId,
                storageService,
              ),
            );
          },
        ),
      ],
      child: const MomEaseApp(),
    ),
  );
}

class MomEaseApp extends StatelessWidget {
  const MomEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
