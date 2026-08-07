import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Temporary placeholder so routing/auth can be exercised end-to-end in
/// Phase 1. Replaced with the full spending/insights dashboard in Phase 5.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.name.split(' ').first ?? 'there'} 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scan'),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Scan'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dashboard coming in Phase 5'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push('/receipts'),
              child: const Text('View receipts'),
            ),
          ],
        ),
      ),
    );
  }
}
