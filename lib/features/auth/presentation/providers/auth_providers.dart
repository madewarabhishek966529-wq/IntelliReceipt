import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/token_storage.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/google_login_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

// --- Core / DI ---------------------------------------------------------

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(tokenStorage: ref.watch(tokenStorageProvider));
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRemoteDataSourceImpl(
    dio: dioClient.dio,
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(box: Hive.box(AppConstants.authBox));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

// --- Use cases -----------------------------------------------------------

final loginUseCaseProvider =
    Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));
final registerUseCaseProvider =
    Provider((ref) => RegisterUseCase(ref.watch(authRepositoryProvider)));
final googleLoginUseCaseProvider =
    Provider((ref) => GoogleLoginUseCase(ref.watch(authRepositoryProvider)));
final forgotPasswordUseCaseProvider = Provider(
    (ref) => ForgotPasswordUseCase(ref.watch(authRepositoryProvider)));
final getCurrentUserUseCaseProvider = Provider(
    (ref) => GetCurrentUserUseCase(ref.watch(authRepositoryProvider)));
final logoutUseCaseProvider =
    Provider((ref) => LogoutUseCase(ref.watch(authRepositoryProvider)));

// --- Auth state ------------------------------------------------------------

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final GoogleLoginUseCase _googleLogin;
  final ForgotPasswordUseCase _forgotPassword;
  final GetCurrentUserUseCase _getCurrentUser;
  final LogoutUseCase _logout;
  final AuthRepository _repository;

  AuthNotifier({
    required LoginUseCase login,
    required RegisterUseCase register,
    required GoogleLoginUseCase googleLogin,
    required ForgotPasswordUseCase forgotPassword,
    required GetCurrentUserUseCase getCurrentUser,
    required LogoutUseCase logout,
    required AuthRepository repository,
  })  : _login = login,
        _register = register,
        _googleLogin = googleLogin,
        _forgotPassword = forgotPassword,
        _getCurrentUser = getCurrentUser,
        _logout = logout,
        _repository = repository,
        super(const AuthState()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final loggedIn = await _repository.isLoggedIn();
    if (!loggedIn) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    final result = await _getCurrentUser();
    result.fold(
      (failure) => state = state.copyWith(status: AuthStatus.unauthenticated),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _login(email: email, password: password);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      ),
    );
  }

  Future<void> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _register(email: email, password: password, name: name);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      ),
    );
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _googleLogin();
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      ),
    );
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _forgotPassword(email);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  Future<void> logout() async {
    await _logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    login: ref.watch(loginUseCaseProvider),
    register: ref.watch(registerUseCaseProvider),
    googleLogin: ref.watch(googleLoginUseCaseProvider),
    forgotPassword: ref.watch(forgotPasswordUseCaseProvider),
    getCurrentUser: ref.watch(getCurrentUserUseCaseProvider),
    logout: ref.watch(logoutUseCaseProvider),
    repository: ref.watch(authRepositoryProvider),
  );
});
