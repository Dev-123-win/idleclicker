import 'package:get_it/get_it.dart';
import 'hive_service.dart';
import 'auth_service.dart';
import 'device_service.dart';
import 'game_service.dart';
import 'ad_service.dart';
import 'sync_service.dart';
import 'notification_service.dart';
import 'security_service.dart';

/// Service locator using GetIt
final GetIt locator = GetIt.instance;

/// Setup all services
Future<void> setupServices() async {
  // Register singletons
  locator.registerLazySingleton<HiveService>(() => HiveService.instance);
  locator.registerLazySingleton<DeviceService>(() => DeviceService());
  locator.registerLazySingleton<SecurityService>(
    () => SecurityService.instance,
  );
  locator.registerLazySingleton<AuthService>(() => AuthService());
  locator.registerLazySingleton<GameService>(() => GameService());
  locator.registerLazySingleton<AdService>(() => AdService());
  locator.registerLazySingleton<SyncService>(() => SyncService());
  locator.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );

  // Initialize services that need async init
  await locator<HiveService>().init();
  await locator<DeviceService>().init();
  await locator<SecurityService>().init();
  await locator<NotificationService>().init();
}

/// Get service from locator
T getService<T extends Object>() => locator<T>();
