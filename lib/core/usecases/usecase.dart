import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// Base class for all use cases
/// 
/// A use case represents a single business operation.
/// It takes [Params] as input and returns [Either<Failure, Type>].
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use this when the use case doesn't require any parameters
class NoParams {
  const NoParams();
}

/// Pagination parameters for list queries
class PaginationParams {
  final int page;
  final int limit;
  final String? cursor;

  const PaginationParams({
    this.page = 1,
    this.limit = 20,
    this.cursor,
  });
}
