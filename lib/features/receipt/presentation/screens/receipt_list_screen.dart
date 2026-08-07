import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/receipt_entity.dart';
import '../providers/receipt_providers.dart';

class ReceiptListScreen extends ConsumerWidget {
  const ReceiptListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(receiptListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Receipts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scan'),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Scan'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(receiptListProvider.notifier).refresh(),
        child: listState.isLoading && listState.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : listState.items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No receipts yet. Tap Scan to add one.')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: listState.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final receipt = listState.items[index];
                      return _ReceiptTile(
                        receipt: receipt,
                        onTap: () => context.push('/receipts/${receipt.id}'),
                      );
                    },
                  ),
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  final ReceiptEntity receipt;
  final VoidCallback onTap;

  const _ReceiptTile({required this.receipt, required this.onTap});

  ({String label, Color color}) get _statusMeta => switch (receipt.status) {
        ReceiptStatus.pending => (label: 'Pending', color: Colors.grey),
        ReceiptStatus.processing => (label: 'Processing', color: AppColors.accent),
        ReceiptStatus.needsReview => (label: 'Needs review', color: AppColors.warning),
        ReceiptStatus.completed => (label: 'Completed', color: AppColors.success),
        ReceiptStatus.failed => (label: 'Failed', color: AppColors.error),
      };

  @override
  Widget build(BuildContext context) {
    final meta = _statusMeta;
    final amount = receipt.totalAmount;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.purchaseDate != null
                          ? DateFormat.yMMMd().format(receipt.purchaseDate!)
                          : DateFormat.yMMMd().format(receipt.createdAt),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: meta.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        meta.label,
                        style: TextStyle(
                          color: meta.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (amount != null)
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
