/// Central place for app-wide constant values.
/// Environment-specific values (base URL, API keys) are injected via
/// --dart-define at build time; see README for the full list of flags.
class AppConstants {
  AppConstants._();

  static const String appName = 'Receipt Intelligence';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 30000;

  // Hive box names
  static const String authBox = 'auth_box';
  static const String receiptsBox = 'receipts_box';
  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';

  // Secure storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // Pagination
  static const int defaultPageSize = 20;
}

class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String googleLogin = '/auth/google';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // Receipts
  static const String receipts = '/receipts';
  static String receiptById(String id) => '/receipts/$id';
  static const String receiptUpload = '/receipts/upload';
  static const String receiptOcr = '/receipts/ocr';

  // Products / price history
  static const String products = '/products';
  static String productPriceHistory(String id) => '/products/$id/price-history';
  static const String storeComparison = '/products/store-comparison';

  // Dashboard / analytics
  static const String dashboardSummary = '/dashboard/summary';
  static const String analyticsSpending = '/analytics/spending';
  static const String analyticsCategories = '/analytics/categories';

  // Budgets
  static const String budgets = '/budgets';

  // Search
  static const String search = '/search';

  // Insights
  static const String insightsWeekly = '/insights/weekly';
  static const String insightsMonthly = '/insights/monthly';
}
