import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/receipt_entity.dart';
import '../repositories/receipt_repository.dart';

class GetReceiptUseCase {
  final ReceiptRepository repository;
  const GetReceiptUseCase(this.repository);

  Future<Either<Failure, ReceiptEntity>> call(String id) {
    return repository.getReceipt(id);
  }
}
