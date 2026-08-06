import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';
import 'token_storage.dart';

/// Central Dio instance used by every remote data source.
///
/// Responsibilities:
/// - attaches the bearer token to outgoing requests
/// - on a 401, attempts a single silent refresh and retries the request
/// - clears the session and rethrows if refresh also fails (caller/UI
///   is responsible for routing to the login screen when it sees an
///   [UnauthorizedException] bubble up through a repository)
class DioClient {
  final Dio dio;
  final TokenStorage tokenStorage;

  DioClient({required this.tokenStorage})
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.baseUrl,
            connectTimeout:
                const Duration(milliseconds: AppConstants.connectTimeoutMs),
            receiveTimeout:
                const Duration(milliseconds: AppConstants.receiveTimeoutMs),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains(ApiEndpoints.refreshToken)) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final opts = error.requestOptions;
              final token = await tokenStorage.accessToken;
              opts.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            } else {
              await tokenStorage.clear();
            }
          }
          handler.next(error);
        },
      ),
    );

    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
      ),
    );
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await tokenStorage.refreshToken;
    if (refreshToken == null) return false;
    try {
      final response = await Dio(BaseOptions(baseUrl: AppConstants.baseUrl))
          .post(ApiEndpoints.refreshToken,
              data: {'refresh_token': refreshToken});
      final newAccess = response.data['access_token'] as String;
      final newRefresh =
          response.data['refresh_token'] as String? ?? refreshToken;
      await tokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
