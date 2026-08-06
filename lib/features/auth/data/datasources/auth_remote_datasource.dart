import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/token_storage.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  });
  Future<UserModel> loginWithGoogle();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({required String token, required String newPassword});
  Future<UserModel> getCurrentUser();
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final TokenStorage tokenStorage;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.dio,
    required this.tokenStorage,
    GoogleSignIn? googleSignIn,
  }) : googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });
      return _persistTokensAndParseUser(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await dio.post(ApiEndpoints.register, data: {
        'email': email,
        'password': password,
        'name': name,
      });
      return _persistTokensAndParseUser(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    try {
      final account = await googleSignIn.signIn();
      if (account == null) {
        throw const AuthException('Google sign-in was cancelled');
      }
      final googleAuth = await account.authentication;
      final response = await dio.post(ApiEndpoints.googleLogin, data: {
        'id_token': googleAuth.idToken,
      });
      return _persistTokensAndParseUser(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await dio.post(ApiEndpoints.resetPassword, data: {
        'token': token,
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dio.get(ApiEndpoints.me);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post(ApiEndpoints.logout);
    } on DioException catch (_) {
      // Best-effort server-side revoke; local session is cleared regardless.
    } finally {
      await tokenStorage.clear();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    }
  }

  Future<UserModel> _persistTokensAndParseUser(dynamic data) async {
    await tokenStorage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Exception _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkException();
    }
    final status = e.response?.statusCode;
    final message = (e.response?.data is Map)
        ? (e.response?.data['detail']?.toString() ?? 'Server error')
        : 'Server error';
    if (status == 401 || status == 403) {
      return AuthException(message);
    }
    return ServerException(message, statusCode: status);
  }
}
