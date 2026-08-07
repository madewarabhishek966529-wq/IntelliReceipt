import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../receipt/presentation/providers/receipt_providers.dart';

/// Shown immediately after upload while the Celery OCR/AI pipeline runs.
/// Listens to [scanStateProvider], which is being driven by the polling
/// use case started from [ScanScreen].
class ScanProcessingScreen extends ConsumerWidget {
  const ScanProcessingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanStateProvider);

    ref.listen(scanStateProvider, (previous, next) {
      if (next.stage == ScanStage.completed || next.stage == ScanStage.needsReview) {
        final receiptId = next.receipt?.id;
        if (receiptId != null) {
          context.pushReplacement('/receipts/$receiptId');
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanning'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (scanState.stage == ScanStage.failed)
              _FailedView(
                message: scanState.errorMessage ?? 'Something went wrong.',
                onRetry: () {
                  ref.read(scanStateProvider.notifier).reset();
                  context.pop();
                },
              )
            else
              _ProcessingView(stage: scanState.stage),
          ],
        ),
      ),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  final ScanStage stage;
  const _ProcessingView({required this.stage});

  String get _label => switch (stage) {
        ScanStage.uploading => 'Uploading receipt...',
        ScanStage.processing => 'Reading your receipt with AI...',
        _ => 'Almost done...',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: AppColors.primary.withOpacity(0.15),
          highlightColor: AppColors.primary.withOpacity(0.35),
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 20),
        Text(_label, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'This usually takes a few seconds.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}

class _FailedView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _FailedView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 56),
        const SizedBox(height: 16),
        Text('Scan failed', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
      ],
    );
  }
}
