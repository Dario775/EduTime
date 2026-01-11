import 'package:get_it/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';

// Core Services
import '../security/encryption_service.dart';

// Data Sources
import '../../data/datasources/local/database_service.dart';
import '../../data/datasources/local/user_local_datasource.dart';
import '../../data/datasources/remote/user_remote_datasource.dart';

// Repositories
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/user_repository.dart';

// Use Cases
import '../../domain/usecases/user/get_current_user.dart';
import '../../domain/usecases/user/sign_in_user.dart';
import '../../domain/usecases/user/sign_out_user.dart';

// BLoCs
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/theme/theme_cubit.dart';

/// GetIt service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> init() async {
  // ==================== External ====================
  
  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ==================== Core Services ====================
  
  // Encryption Service (Android Keystore / iOS Keychain)
  sl.registerLazySingleton<EncryptionService>(
    () => EncryptionService(prefs: sl()),
  );
  
  // Database Service (Encrypted Isar)
  final databaseService = DatabaseService.getInstance(sl());
  sl.registerLazySingleton<DatabaseService>(() => databaseService);
  
  // Initialize encrypted database
  final isar = await databaseService.initialize();
  sl.registerLazySingleton<Isar>(() => isar);

  // ==================== Data Sources ====================
  
  // Local
  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(sharedPreferences: sl()),
  );
  
  // Remote
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(),
  );

  // ==================== Repositories ====================
  
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );

  // ==================== Use Cases ====================
  
  // User
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SignInUser(sl()));
  sl.registerLazySingleton(() => SignOutUser(sl()));

  // ==================== BLoCs ====================
  
  sl.registerFactory(
    () => AuthBloc(
      getCurrentUser: sl(),
      signInUser: sl(),
      signOutUser: sl(),
    ),
  );
  
  sl.registerFactory(
    () => ThemeCubit(sharedPreferences: sl()),
  );
}

/// Clean up resources on app close
Future<void> dispose() async {
  // Close database
  if (sl.isRegistered<DatabaseService>()) {
    await sl<DatabaseService>().close();
  }
  
  // Reset service locator
  await sl.reset();
}
