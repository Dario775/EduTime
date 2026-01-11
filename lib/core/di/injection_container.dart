import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// BLoCs
import '../../presentation/blocs/theme/theme_cubit.dart';

/// GetIt service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
/// 
/// This is a simplified version for demo purposes.
/// Full version includes Firebase, Isar DB, repositories, etc.
Future<void> init() async {
  // ==================== External ====================
  
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ==================== BLoCs ====================
  
  sl.registerFactory(
    () => ThemeCubit(sharedPreferences: sl()),
  );
}

/// Clean up resources on app close
Future<void> dispose() async {
  // Reset service locator
  await sl.reset();
}
