import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
import 'ui/screens/withdrawal_screen.dart';
import 'ui/screens/referral_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/help_screen.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Hide status bar and navigation bar (Immersive Mode)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
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
        ChangeNotifierProvider<GameService>(create: (_) => GameService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        ChangeNotifierProvider<AdService>(create: (_) => AdService()),
      ],

      child: MaterialApp(
        title: 'TapMine',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const NetworkAwareWidget(child: AppNavigator()),
      ),
    );
  }
}

class NetworkAwareWidget extends StatelessWidget {
  final Widget child;
  const NetworkAwareWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final results = snapshot.data;
        final isOffline =
            results != null &&
            results.isNotEmpty &&
            results.contains(ConnectivityResult.none) &&
            results.length == 1;

        if (isOffline) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 64, color: Colors.white54),
                  SizedBox(height: 16),
                  Text(
                    'No Internet Connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please reconnect to continue mining.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        }
        return child;
      },
    );
  }
} // End of NetworkAwareWidget

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
  Future<void>? _initializationFuture;
  bool _isLoggedIn = false;

  final List<AppScreen> _gameScreens = [
    AppScreen.missions,
    AppScreen.home,
    AppScreen.leaderboard,
    AppScreen.autoClicker,
    AppScreen.profile,
  ];

  Widget _buildNavItem(IconData icon, String label, AppScreen screen) {
    final isActive = _currentScreen == screen;
    return GestureDetector(
      onTap: () => _navigateTo(screen),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: isActive
                ? NeumorphicDecoration.flat(
                    borderRadius: 25,
                    isPressed: true,
                  ).copyWith(
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  )
                : null,
            child: Icon(
              icon,
              color: isActive ? AppTheme.primary : Colors.white38,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppTheme.primary : Colors.white38,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: NeumorphicDecoration.flat(borderRadius: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, 'Home', AppScreen.home),
          _buildNavItem(Icons.flag, 'Missions', AppScreen.missions),
          _buildNavItem(Icons.smart_toy, 'Auto', AppScreen.autoClicker),
          _buildNavItem(Icons.leaderboard, 'Rank', AppScreen.leaderboard),
          _buildNavItem(Icons.person, 'Profile', AppScreen.profile),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1); // Home is index 1
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authService = context.read<AuthService>();
      _gameService = context.read<GameService>();
      // Start initialization immediately and store the future
      _initializationFuture = _runInitialization();
    });
  }

  /// Runs all initialization logic during the splash screen
  Future<void> _runInitialization() async {
    _authService = context.read<AuthService>();
    _gameService = context.read<GameService>();

    if (_authService.isLoggedIn) {
      final user = await _authService.getUserModel();
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        _gameService.addListener(() {
          if (mounted) {
            setState(() {
              _currentUser = _gameService.currentUser;
            });
          }
        });
        await _gameService.initialize(user);
        return;
      }
    }
    _isLoggedIn = false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSplashComplete() {
    // Initialization already ran during splash, just navigate to correct screen
    if (_isLoggedIn && _currentUser != null) {
      setState(() => _currentScreen = AppScreen.home);
    } else {
      setState(() => _currentScreen = AppScreen.login);
    }
  }

  void _onLoginSuccess() async {
    _authService = context.read<AuthService>();
    _gameService = context.read<GameService>();

    final user = await _authService.getUserModel();
    if (user != null) {
      _gameService.addListener(() {
        if (mounted) {
          setState(() {
            _currentUser = _gameService.currentUser;
          });
        }
      });
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
              backgroundColor: AppTheme.accent.withValues(alpha: 0.9),
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
        initializationFuture: _initializationFuture,
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

    // Check if the current screen is a standalone screen (not in PageView)
    if (!_gameScreens.contains(_currentScreen)) {
      return _buildScreen(_currentScreen);
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: _gameScreens.map((screen) => _buildScreen(screen)).toList(),
      ),
      bottomNavigationBar: _buildBottomNav(),
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
          onNavigateToWithdrawal: () => _navigateTo(AppScreen.withdrawal),
          onNavigateToReferral: () => _navigateTo(AppScreen.referral),
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
          onNavigateToSettings: () => _navigateTo(AppScreen.settings),
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
      case AppScreen.withdrawal:
        return WithdrawalScreen(
          user: _currentUser!,
          gameService: _gameService,
          onBack: () => _navigateTo(AppScreen.home),
        );
      case AppScreen.referral:
        return ReferralScreen(
          user: _currentUser!,
          gameService: _gameService,
          onBack: () => _navigateTo(AppScreen.home),
        );
      case AppScreen.settings:
        return SettingsScreen(
          user: _currentUser!,
          gameService: _gameService,
          onBack: () => _navigateTo(AppScreen.profile),
          onNavigateToHelp: () => _navigateTo(AppScreen.help),
        );
      case AppScreen.help:
        return HelpScreen(onBack: () => _navigateTo(AppScreen.settings));
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
  withdrawal,
  referral,
  settings,
  help,
}
