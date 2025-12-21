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
import 'core/services/notification_service.dart';

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

  // Initialize Notification Service
  await NotificationService().initialize();

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
        Provider<NotificationService>(create: (_) => NotificationService()),
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
  late PageController _pageController;

  final List<AppScreen> _gameScreens = [
    AppScreen.missions,
    AppScreen.home,
    AppScreen.leaderboard,
    AppScreen.autoClicker,
    AppScreen.profile,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1); // Home is index 1
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authService = context.read<AuthService>();
      _gameService = context.read<GameService>();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSplashComplete() async {
    _authService = context.read<AuthService>();
    _gameService = context.read<GameService>();

    if (_authService.isLoggedIn) {
      final user = await _authService.getUserModel();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _currentScreen = AppScreen.home;
        });
        await _gameService.initialize(user);
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
      setState(() {
        _currentUser = user;
        _currentScreen = AppScreen.home;
      });
      await _gameService.initialize(user);
    }
  }

  void _onLogout() async {
    await _authService.signOut();
    _gameService.dispose();
    _currentUser = null;
    setState(() => _currentScreen = AppScreen.login);
  }

  void _navigateTo(AppScreen screen) {
    if (_gameScreens.contains(screen)) {
      final index = _gameScreens.indexOf(screen);
      if (_currentScreen == screen) return;

      setState(() => _currentScreen = screen);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    } else {
      setState(() => _currentScreen = screen);
    }
  }

  void _onPageChanged(int index) {
    if (mounted) {
      setState(() => _currentScreen = _gameScreens[index]);
    }
  }

  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;

        final now = DateTime.now();
        final isWarningStep =
            _lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2);

        if (isWarningStep) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.exit_to_app, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Press back again to exit',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: AppTheme.accent.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    if (_currentScreen == AppScreen.splash) {
      return SplashScreen(
        key: const ValueKey('splash'),
        onComplete: _onSplashComplete,
      );
    }

    if (_currentScreen == AppScreen.login) {
      return LoginScreen(
        key: const ValueKey('login'),
        onLoginSuccess: _onLoginSuccess,
      );
    }

    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: _gameScreens.map((screen) => _buildScreen(screen)).toList(),
      ),
    );
  }

  Widget _buildScreen(AppScreen screen) {
    switch (screen) {
      case AppScreen.home:
        return HomeScreen(
          user: _currentUser!,
          gameService: _gameService,
          onNavigateToMissions: () => _navigateTo(AppScreen.missions),
          onNavigateToProfile: () => _navigateTo(AppScreen.profile),
          onNavigateToAutoClicker: () => _navigateTo(AppScreen.autoClicker),
          onNavigateToLeaderboard: () => _navigateTo(AppScreen.leaderboard),
        );
      case AppScreen.missions:
        return MissionScreen(
          user: _currentUser!,
          gameService: _gameService,
          onBack: () => _navigateTo(AppScreen.home),
          onMissionStarted: () => _navigateTo(AppScreen.home),
        );
      case AppScreen.profile:
        return ProfileScreen(
          user: _currentUser!,
          gameService: _gameService,
          onBack: () => _navigateTo(AppScreen.home),
          onLogout: _onLogout,
        );
      case AppScreen.autoClicker:
        return AutoClickerScreen(
          user: _currentUser!,
          gameService: _gameService,
          onBack: () => _navigateTo(AppScreen.home),
        );
      case AppScreen.leaderboard:
        return LeaderboardScreen(
          user: _currentUser!,
          gameService: _gameService,
          onBack: () => _navigateTo(AppScreen.home),
        );
      default:
        return const SizedBox.shrink();
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
