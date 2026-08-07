import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/receipt_remote_datasource.dart';
import '../../data/repositories/receipt_repository_impl.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../../domain/usecases/get_receipt_usecase.dart';
import '../../domain/usecases/list_receipts_usecase.dart';
import '../../domain/usecases/poll_receipt_status_usecase.dart';
import '../../domain/usecases/update_receipt_item_usecase.dart';
import '../../domain/usecases/upload_receipt_usecase.dart';

// --- DI --------------------------------------------------------------------

final receiptRemoteDataSourceProvider = Provider<ReceiptRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ReceiptRemoteDataSourceImpl(dio: dioClient.dio);
});

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepositoryImpl(
    remoteDataSource: ref.watch(receiptRemoteDataSourceProvider),
  );
});

final uploadReceiptUseCaseProvider =
    Provider((ref) => UploadReceiptUseCase(ref.watch(receiptRepositoryProvider)));
final getReceiptUseCaseProvider =
    Provider((ref) => GetReceiptUseCase(ref.watch(receiptRepositoryProvider)));
final listReceiptsUseCaseProvider =
    Provider((ref) => ListReceiptsUseCase(ref.watch(receiptRepositoryProvider)));
final pollReceiptStatusUseCaseProvider =
    Provider((ref) => PollReceiptStatusUseCase(ref.watch(receiptRepositoryProvider)));
final updateReceiptItemUseCaseProvider =
    Provider((ref) => UpdateReceiptItemUseCase(ref.watch(receiptRepositoryProvider)));

// --- Upload / scan flow state ----------------------------------------------

enum ScanStage { idle, uploading, processing, needsReview, completed, failed }

class ScanState {
  final ScanStage stage;
  final ReceiptEntity? receipt;
  final String? errorMessage;

  const ScanState({this.stage = ScanStage.idle, this.receipt, this.errorMessage});

  ScanState copyWith({ScanStage? stage, ReceiptEntity? receipt, String? errorMessage}) {
    return ScanState(
      stage: stage ?? this.stage,
      receipt: receipt ?? this.receipt,
      errorMessage: errorMessage,
    );
  }
}

class ScanNotifier extends StateNotifier<ScanState> {
  final UploadReceiptUseCase _upload;
  final PollReceiptStatusUseCase _poll;

  ScanNotifier({
    required UploadReceiptUseCase upload,
    required PollReceiptStatusUseCase poll,
  })  : _upload = upload,
        _poll = poll,
        super(const ScanState());

  Future<void> scanAndUpload(File file) async {
    state = state.copyWith(stage: ScanStage.uploading, errorMessage: null);

    final uploadResult = await _upload(file);
    final failure = uploadResult.fold((f) => f, (_) => null);
    if (failure != null) {
      state = state.copyWith(stage: ScanStage.failed, errorMessage: failure.message);
      return;
    }

    final (receiptId, _) = uploadResult.getOrElse(() => throw StateError('unreachable'));
    state = state.copyWith(stage: ScanStage.processing);

    await for (final result in _poll(receiptId)) {
      result.fold(
        (f) => state = state.copyWith(stage: ScanStage.failed, errorMessage: f.message),
        (receipt) {
          final stage = switch (receipt.status) {
            ReceiptStatus.completed => ScanStage.completed,
            ReceiptStatus.needsReview => ScanStage.needsReview,
            ReceiptStatus.failed => ScanStage.failed,
            _ => ScanStage.processing,
          };
          state = state.copyWith(stage: stage, receipt: receipt);
        },
      );
    }
  }

  void reset() => state = const ScanState();
}

final scanStateProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier(
    upload: ref.watch(uploadReceiptUseCaseProvider),
    poll: ref.watch(pollReceiptStatusUseCaseProvider),
  );
});

// --- Receipt list state ------------------------------------------------

class ReceiptListState {
  final List<ReceiptEntity> items;
  final int total;
  final bool isLoading;
  final String? errorMessage;

  const ReceiptListState({
    this.items = const [],
    this.total = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  ReceiptListState copyWith({
    List<ReceiptEntity>? items,
    int? total,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ReceiptListState(
      items: items ?? this.items,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ReceiptListNotifier extends StateNotifier<ReceiptListState> {
  final ListReceiptsUseCase _listReceipts;

  ReceiptListNotifier(this._listReceipts) : super(const ReceiptListState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _listReceipts();
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (data) {
        final (items, total) = data;
        state = state.copyWith(isLoading: false, items: items, total: total);
      },
    );
  }
}

final receiptListProvider =
    StateNotifierProvider<ReceiptListNotifier, ReceiptListState>((ref) {
  return ReceiptListNotifier(ref.watch(listReceiptsUseCaseProvider));
});
