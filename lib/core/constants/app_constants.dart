class AppConstants {
  AppConstants._();

  // API Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // Token expiry thresholds
  static const int tokenRefreshThreshold = 24 * 60 * 60; // 24 hours in seconds

  // Onboarding
  static const String hasSeenOnboardingKey = 'has_seen_onboarding';

  // Biometric
  static const String biometricEnabledKey = 'biometric_enabled';

  // SharedPreferences keys
  static const String cachedUserKey = 'cached_user';
  static const String tokenExpiryKey = 'token_expiry';

  // Secure storage keys
  static const String jwtTokenKey = 'jwt_token';

  // Resend verification cooldown
  static const int resendCooldownSeconds = 60;

  // Pagination defaults
  static const int defaultPageLimit = 10;

  // Rate limiting
  static const int maxRetryAttempts = 3;
  static const int retryDelayMs = 1000;

  // Splash screen duration
  static const int splashDurationMs = 2500;
}
