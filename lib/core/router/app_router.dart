import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/ocr/presentation/scan_processing_screen.dart';
import '../../features/ocr/presentation/scan_screen.dart';
import '../../features/receipt/presentation/screens/receipt_detail_screen.dart';
import '../../features/receipt/presentation/screens/receipt_list_screen.dart';

/// Listenable bridge so GoRouter can react to Riverpod's [authStateProvider]
/// without rebuilding the whole router tree on every emission.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loggedIn = authState.status == AuthStatus.authenticated;
      final loggingIn = ['/login', '/register', '/forgot-password']
          .contains(state.matchedLocation);

      if (authState.status == AuthStatus.unknown) return null;
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/receipts',
        builder: (context, state) => const ReceiptListScreen(),
      ),
      GoRoute(
        path: '/receipts/:id',
        builder: (context, state) =>
            ReceiptDetailScreen(receiptId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: '/scan/processing',
        builder: (context, state) => const ScanProcessingScreen(),
      ),
    ],
  );
});
