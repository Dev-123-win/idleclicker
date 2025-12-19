import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/services/auth_service.dart';
import 'core/services/game_service.dart';
import 'core/services/ad_service.dart';
import 'core/models/user_model.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/mission_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/autoclicker_screen.dart';
import 'ui/screens/leaderboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Ad Service
  await AdService().initialize();

  runApp(const TapMineApp());
}

class TapMineApp extends StatelessWidget {
  const TapMineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<GameService>(create: (_) => GameService()),
        ChangeNotifierProvider<AdService>(create: (_) => AdService()),
      ],
      child: MaterialApp(
        title: 'TapMine',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppNavigator(),
      ),
    );
  }
}

/// Main navigation controller
class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  AppScreen _currentScreen = AppScreen.splash;
  UserModel? _currentUser;

  late AuthService _authService;
  late GameService _gameService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authService = context.read<AuthService>();
      _gameService = context.read<GameService>();
    });
  }

  void _onSplashComplete() async {
    _authService = context.read<AuthService>();

    // Check if user is already logged in
    if (_authService.isLoggedIn) {
      final user = await _authService.getUserModel();
      if (user != null) {
        _currentUser = user;
        await _gameService.initialize(user);
        setState(() => _currentScreen = AppScreen.home);
        return;
      }
    }

    setState(() => _currentScreen = AppScreen.login);
  }

  void _onLoginSuccess() async {
    _authService = context.read<AuthService>();
    _gameService = context.read<GameService>();

    final user = await _authService.getUserModel();
    if (user != null) {
      _currentUser = user;
      await _gameService.initialize(user);
      setState(() => _currentScreen = AppScreen.home);
    }
  }

  void _onLogout() async {
    await _authService.signOut();
    _gameService.dispose();
    _currentUser = null;
    setState(() => _currentScreen = AppScreen.login);
  }

  void _navigateTo(AppScreen screen) {
    setState(() => _currentScreen = screen);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(animation);

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(animation);

        final scaleAnimation = Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(animation);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          ),
        );
      },
      child: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case AppScreen.splash:
        return SplashScreen(
          key: const ValueKey('splash'),
          onComplete: _onSplashComplete,
        );

      case AppScreen.login:
        return LoginScreen(
          key: const ValueKey('login'),
          onLoginSuccess: _onLoginSuccess,
        );

      case AppScreen.home:
        if (_currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return HomeScreen(
          key: const ValueKey('home'),
          user: _currentUser!,
          gameService: _gameService,
          onNavigateToMissions: () => _navigateTo(AppScreen.missions),
          onNavigateToProfile: () => _navigateTo(AppScreen.profile),
          onNavigateToAutoClicker: () => _navigateTo(AppScreen.autoClicker),
          onNavigateToLeaderboard: () => _navigateTo(AppScreen.leaderboard),
        );

      case AppScreen.missions:
        if (_currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return MissionScreen(
          key: const ValueKey('missions'),
          user: _currentUser!,
          gameService: _gameService,
          onBack: () => _navigateTo(AppScreen.home),
          onMissionStarted: () => _navigateTo(AppScreen.home),
        );

      case AppScreen.profile:
        if (_currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ProfileScreen(
          key: const ValueKey('profile'),
          user: _currentUser!,
          gameService: _gameService,
          onBack: () => _navigateTo(AppScreen.home),
          onLogout: _onLogout,
        );

      case AppScreen.autoClicker:
        if (_currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return AutoClickerScreen(
          key: const ValueKey('autoclicker'),
          user: _currentUser!,
          gameService: _gameService,
          onBack: () => _navigateTo(AppScreen.home),
        );

      case AppScreen.leaderboard:
        if (_currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return LeaderboardScreen(
          key: const ValueKey('leaderboard'),
          user: _currentUser!,
          onBack: () => _navigateTo(AppScreen.home),
        );
    }
  }
}

enum AppScreen {
  splash,
  login,
  home,
  missions,
  profile,
  autoClicker,
  leaderboard,
}
