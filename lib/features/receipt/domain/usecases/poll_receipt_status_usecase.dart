import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/receipt_entity.dart';
import '../repositories/receipt_repository.dart';

/// Polls a receipt's status until it leaves the pending/processing state
/// or the [timeout] is hit. Used right after upload to drive the
/// "scanning..." UI without needing a websocket for Phase 2.
class PollReceiptStatusUseCase {
  final ReceiptRepository repository;
  const PollReceiptStatusUseCase(this.repository);

  Stream<Either<Failure, ReceiptEntity>> call(
    String receiptId, {
    Duration interval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 2),
  }) async* {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final result = await repository.getReceipt(receiptId);
      yield result;

      final shouldStop = result.fold(
        (_) => true, // stop on error; caller decides whether to retry
        (receipt) => !receipt.isProcessing,
      );
      if (shouldStop) return;

      await Future.delayed(interval);
    }
  }
}
