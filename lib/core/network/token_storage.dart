import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Wraps [FlutterSecureStorage] for JWT access/refresh token persistence.
/// Kept as a thin, mockable class so the Dio interceptor and auth
/// repository don't touch the platform channel directly.
class TokenStorage {
  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(
        key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(
        key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  Future<String?> get accessToken =>
      _storage.read(key: AppConstants.accessTokenKey);

  Future<String?> get refreshToken =>
      _storage.read(key: AppConstants.refreshTokenKey);

  Future<void> clear() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  Future<bool> get hasValidSession async => (await accessToken) != null;
}
