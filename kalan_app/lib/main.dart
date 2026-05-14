import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kalan_app/core/theme/app_theme.dart';
import 'package:kalan_app/core/utils/text_scale.dart';
import 'package:kalan_app/data/local/database_helper.dart';
import 'package:kalan_app/data/remote/supabase_service.dart';
import 'package:kalan_app/data/repositories/deck_repository_impl.dart';
import 'package:kalan_app/data/repositories/flashcard_repository_impl.dart';
import 'package:kalan_app/data/repositories/quiz_repository_impl.dart';
import 'package:kalan_app/data/repositories/user_repository_impl.dart';
import 'package:kalan_app/data/repositories/badge_repository_impl.dart';
import 'package:kalan_app/presentation/blocs/deck/deck_bloc.dart';
import 'package:kalan_app/presentation/blocs/deck/deck_event.dart';
import 'package:kalan_app/presentation/blocs/flashcard/flashcard_bloc.dart';
import 'package:kalan_app/presentation/blocs/quiz/quiz_bloc.dart';
import 'package:kalan_app/presentation/blocs/sync/sync_bloc.dart';
import 'package:kalan_app/presentation/blocs/user/user_bloc.dart';
import 'package:kalan_app/presentation/blocs/badge/badge_bloc.dart';
import 'package:kalan_app/presentation/blocs/leaderboard/leaderboard_bloc.dart';
import 'package:kalan_app/data/repositories/leaderboard_repository_impl.dart';
import 'package:kalan_app/services/sync_service.dart';
import 'package:kalan_app/presentation/screens/home_screen.dart';
import 'package:kalan_app/presentation/screens/login_screen.dart';
import 'package:kalan_app/services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  // Initialize Local AI - Gemma will auto-initialize on first use

  final dbHelper = DatabaseHelper.instance;
  final connectivity = ConnectivityService();
  final deckRepo = DeckRepositoryImpl(dbHelper, connectivity);
  final flashcardRepo = FlashcardRepositoryImpl(dbHelper, connectivity);
  final quizRepo = QuizRepositoryImpl(dbHelper, connectivity);
  final userRepo = UserRepositoryImpl(dbHelper, connectivity);
  final badgeRepo = BadgeRepositoryImpl(dbHelper, connectivity);
  final leaderboardRepo = LeaderboardRepositoryImpl(dbHelper, connectivity);

  if (SupabaseService.currentUser != null) {
    SyncService.instance.init();
    SyncService.instance.processQueue();
  }

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DeckRepositoryImpl>.value(value: deckRepo),
        RepositoryProvider<FlashcardRepositoryImpl>.value(value: flashcardRepo),
        RepositoryProvider<QuizRepositoryImpl>.value(value: quizRepo),
        RepositoryProvider<UserRepositoryImpl>.value(value: userRepo),
        RepositoryProvider<BadgeRepositoryImpl>.value(value: badgeRepo),
        RepositoryProvider<LeaderboardRepositoryImpl>.value(value: leaderboardRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DeckBloc>(
            create: (_) => DeckBloc(deckRepo)..add(const LoadDecks()),
          ),
          BlocProvider<FlashcardBloc>(
            create: (_) => FlashcardBloc(flashcardRepo),
          ),
          BlocProvider<QuizBloc>(
            create: (_) => QuizBloc(quizRepo),
          ),
          BlocProvider<UserBloc>(
            create: (_) => UserBloc(userRepo),
          ),
          BlocProvider<BadgeBloc>(
            create: (_) => BadgeBloc(badgeRepo),
          ),
          BlocProvider<LeaderboardBloc>(
            create: (_) => LeaderboardBloc(leaderboardRepo),
          ),
          BlocProvider<SyncBloc>(create: (_) => SyncBloc()),
        ],
        child: const KalanApp(),
      ),
    ),
  );
}

class KalanApp extends StatelessWidget {
  const KalanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KALAN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.light,
      home: const AuthWrapper(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(TextScale.normal.factor),
          ),
          child: child!,
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return SupabaseService.currentUser == null
        ? const LoginScreen()
        : const HomeScreen();
  }
}
