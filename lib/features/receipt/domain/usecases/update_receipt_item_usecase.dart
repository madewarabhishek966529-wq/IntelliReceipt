import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/receipt_entity.dart';
import '../repositories/receipt_repository.dart';

class UpdateReceiptItemUseCase {
  final ReceiptRepository repository;
  const UpdateReceiptItemUseCase(this.repository);

  Future<Either<Failure, ReceiptItemEntity>> call({
    required String receiptId,
    required String itemId,
    String? displayName,
    double? quantity,
    double? mrp,
    double? discount,
    double? tax,
    double? finalPrice,
  }) {
    return repository.updateReceiptItem(
      receiptId: receiptId,
      itemId: itemId,
      displayName: displayName,
      quantity: quantity,
      mrp: mrp,
      discount: discount,
      tax: tax,
      finalPrice: finalPrice,
    );
  }
}
