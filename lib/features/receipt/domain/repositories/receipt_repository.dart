import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/receipt_entity.dart';

abstract class ReceiptRepository {
  /// Uploads the given image/PDF file and kicks off server-side OCR/AI
  /// processing. Returns the created receipt's id and initial status.
  Future<Either<Failure, (String id, ReceiptStatus status)>> uploadReceipt(File file);

  Future<Either<Failure, ReceiptEntity>> getReceipt(String id);

  Future<Either<Failure, (List<ReceiptEntity> items, int total)>> listReceipts({
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, ReceiptItemEntity>> updateReceiptItem({
    required String receiptId,
    required String itemId,
    String? displayName,
    double? quantity,
    double? mrp,
    double? discount,
    double? tax,
    double? finalPrice,
  });
}
