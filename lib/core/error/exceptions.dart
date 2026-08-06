/// Data-layer exceptions. Data sources throw these; repositories catch
/// them and convert to [Failure]s before returning to the domain layer.
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException(this.message, {this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Local cache error']);
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Session expired']);
}
