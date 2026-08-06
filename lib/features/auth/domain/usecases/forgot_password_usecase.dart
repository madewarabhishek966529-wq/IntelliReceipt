import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;
  const ForgotPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String email) {
    if (email.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Email is required')));
    }
    return repository.forgotPassword(email.trim());
  }
}
