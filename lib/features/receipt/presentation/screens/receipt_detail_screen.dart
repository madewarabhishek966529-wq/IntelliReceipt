import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/receipt_entity.dart';
import '../providers/receipt_providers.dart';

/// Functional baseline receipt view for Phase 2: image, extracted items,
/// totals, and a NEEDS_REVIEW banner. The polished "Smart Receipt Screen"
/// (store logo, category badges, edit/delete/share) lands in Phase 3.
class ReceiptDetailScreen extends ConsumerWidget {
  final String receiptId;
  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(_receiptDetailProvider(receiptId));

    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (receipt) => _ReceiptBody(receipt: receipt),
      ),
    );
  }
}

final _receiptDetailProvider =
    FutureProvider.family<ReceiptEntity, String>((ref, id) async {
  final useCase = ref.watch(getReceiptUseCaseProvider);
  final result = await useCase(id);
  return result.fold((failure) => throw failure.message, (receipt) => receipt);
});

class _ReceiptBody extends StatelessWidget {
  final ReceiptEntity receipt;
  const _ReceiptBody({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (receipt.status == ReceiptStatus.needsReview)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Some details need review. Tap an item to correct it.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        if (receipt.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              receipt.imageUrl!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 220,
                color: Colors.grey.shade200,
                child: const Icon(Icons.receipt_long, size: 48, color: Colors.grey),
              ),
            ),
          ),
        const SizedBox(height: 20),
        if (receipt.purchaseDate != null)
          Text(
            DateFormat.yMMMMd().format(receipt.purchaseDate!),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final item in receipt.items) _ItemRow(item: item),
                if (receipt.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No items extracted yet.'),
                  ),
                const Divider(height: 32),
                _SummaryRow(label: 'Subtotal', value: receipt.subtotal),
                _SummaryRow(label: 'Tax', value: receipt.taxAmount),
                _SummaryRow(label: 'Discount', value: receipt.discountAmount, isNegative: true),
                const SizedBox(height: 8),
                _SummaryRow(label: 'Total', value: receipt.totalAmount, isBold: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ReceiptItemEntity item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final lowConfidence = (item.aiConfidence ?? 1.0) < 0.55;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    item.displayName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                if (lowConfidence) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.flag_outlined, size: 16, color: AppColors.warning),
                ],
              ],
            ),
          ),
          Text('×${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)}'),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              '₹${item.finalPrice.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double? value;
  final bool isNegative;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isNegative = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    final style = isBold
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style?.copyWith(color: isBold ? null : Colors.grey)),
          Text(
            '${isNegative ? '-' : ''}₹${value!.toStringAsFixed(2)}',
            style: style,
          ),
        ],
      ),
    );
  }
}
