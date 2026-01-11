part of 'auth_bloc.dart';

/// Base class for all authentication states
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before authentication check
final class AuthInitial extends AuthState {}

/// Loading state during authentication operations
final class AuthLoading extends AuthState {}

/// Authenticated state with user data
final class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state
final class AuthUnauthenticated extends AuthState {}

/// Error state with failure message
final class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
