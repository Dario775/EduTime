/// Custom exception for server errors
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic originalError;

  const ServerException({
    required this.message,
    this.statusCode,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'ServerException: $message (code: $code)';
}

/// Custom exception for cache errors
class CacheException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const CacheException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'CacheException: $message';
}

/// Custom exception for network errors
class NetworkException implements Exception {
  final String message;
  final dynamic originalError;

  const NetworkException({
    this.message = 'No hay conexión a internet',
    this.originalError,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AuthException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? fieldErrors;

  const ValidationException({
    required this.message,
    this.fieldErrors,
  });

  @override
  String toString() => 'ValidationException: $message';
}

/// Custom exception when a resource is not found
class NotFoundException implements Exception {
  final String message;
  final String? resourceType;
  final String? resourceId;

  const NotFoundException({
    this.message = 'Recurso no encontrado',
    this.resourceType,
    this.resourceId,
  });

  @override
  String toString() => 'NotFoundException: $message';
}
