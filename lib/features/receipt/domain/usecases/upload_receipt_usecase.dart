import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/receipt_entity.dart';
import '../repositories/receipt_repository.dart';

class UploadReceiptUseCase {
  final ReceiptRepository repository;
  const UploadReceiptUseCase(this.repository);

  Future<Either<Failure, (String id, ReceiptStatus status)>> call(File file) {
    return repository.uploadReceipt(file);
  }
}
