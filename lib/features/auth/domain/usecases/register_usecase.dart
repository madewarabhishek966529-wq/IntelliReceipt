import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;
  const RegisterUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required String name,
  }) {
    if (name.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Name is required')));
    }
    if (password.length < 8) {
      return Future.value(
        const Left(ValidationFailure('Password must be at least 8 characters')),
      );
    }
    return repository.register(
      email: email.trim(),
      password: password,
      name: name.trim(),
    );
  }
}
