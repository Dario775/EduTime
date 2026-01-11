import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/user.dart';

/// User repository interface
/// 
/// Defines the contract for user-related data operations.
/// The implementation will be in the data layer.
abstract class UserRepository {
  /// Get the currently authenticated user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Sign in with email and password
  Future<Either<Failure, User>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Sign in with Google
  Future<Either<Failure, User>> signInWithGoogle();

  /// Sign up with email and password
  Future<Either<Failure, User>> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign out the current user
  Future<Either<Failure, void>> signOut();

  /// Update user profile
  Future<Either<Failure, User>> updateProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Update user settings
  Future<Either<Failure, User>> updateSettings(UserSettings settings);

  /// Delete user account
  Future<Either<Failure, void>> deleteAccount();

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;
}
