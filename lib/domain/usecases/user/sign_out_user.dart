import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/user_repository.dart';

/// Sign Out User Use Case
/// 
/// Signs out the currently authenticated user.
class SignOutUser implements UseCase<void, NoParams> {
  final UserRepository repository;

  SignOutUser(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.signOut();
  }
}
