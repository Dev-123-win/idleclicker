import 'package:flutter/material.dart';

/// App route names
class Routes {
  Routes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String missions = '/missions';
  static const String referral = '/referral';
  static const String withdrawal = '/withdrawal';
  static const String profile = '/profile';
  static const String faq = '/faq';
  static const String settings = '/settings';
}

/// Route generator for named routes
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // TODO: Implement routes after creating screens
    switch (settings.name) {
      case Routes.splash:
      case Routes.login:
      case Routes.register:
      case Routes.forgotPassword:
      case Routes.home:
      case Routes.missions:
      case Routes.referral:
      case Routes.withdrawal:
      case Routes.profile:
      case Routes.faq:
      case Routes.settings:
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
