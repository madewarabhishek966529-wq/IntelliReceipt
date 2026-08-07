import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/receipt_entity.dart';
import '../repositories/receipt_repository.dart';

class ListReceiptsUseCase {
  final ReceiptRepository repository;
  const ListReceiptsUseCase(this.repository);

  Future<Either<Failure, (List<ReceiptEntity> items, int total)>> call({
    int page = 1,
    int pageSize = 20,
  }) {
    return repository.listReceipts(page: page, pageSize: pageSize);
  }
}
