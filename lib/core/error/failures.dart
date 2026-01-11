import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
/// 
/// Failures represent expected error conditions that the app
/// should handle gracefully (e.g., no internet, invalid input).
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic originalError;

  const Failure({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  List<Object?> get props => [message, code];
}

// ==================== Server Failures ====================

/// Failure when server returns an error
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Failure when there's no internet connection
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No hay conexión a internet',
    super.code = 'NETWORK_ERROR',
  });
}

/// Failure when request times out
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'La solicitud tardó demasiado tiempo',
    super.code = 'TIMEOUT',
  });
}

// ==================== Cache Failures ====================

/// Failure when local cache operation fails
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code = 'CACHE_ERROR',
    super.originalError,
  });
}

/// Failure when cached data is not found
class CacheNotFoundFailure extends Failure {
  const CacheNotFoundFailure({
    super.message = 'No se encontraron datos en caché',
    super.code = 'CACHE_NOT_FOUND',
  });
}

// ==================== Auth Failures ====================

/// Failure during authentication
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.originalError,
  });
}

/// Failure when user is not authenticated
class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure({
    super.message = 'Debes iniciar sesión para continuar',
    super.code = 'UNAUTHENTICATED',
  });
}

/// Failure when user doesn't have permission
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'No tienes permisos para realizar esta acción',
    super.code = 'UNAUTHORIZED',
  });
}

/// Failure when user credentials are invalid
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({
    super.message = 'Credenciales inválidas',
    super.code = 'INVALID_CREDENTIALS',
  });
}

// ==================== Validation Failures ====================

/// Failure when input validation fails
class ValidationFailure extends Failure {
  final Map<String, List<String>>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

// ==================== Resource Failures ====================

/// Failure when a resource is not found
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Recurso no encontrado',
    super.code = 'NOT_FOUND',
  });
}

/// Failure when a resource already exists
class AlreadyExistsFailure extends Failure {
  const AlreadyExistsFailure({
    super.message = 'El recurso ya existe',
    super.code = 'ALREADY_EXISTS',
  });
}

// ==================== Generic Failures ====================

/// Unknown failure for unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Ha ocurrido un error inesperado',
    super.code = 'UNKNOWN_ERROR',
    super.originalError,
  });
}
