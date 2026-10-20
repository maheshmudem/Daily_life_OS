class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resendVerification = '/auth/resend-verification';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';

  // User & Profile
  static const String userProfile = '/users/profile';
  static const String preferences = '/users/preferences';
  static const String deleteAccount = '/users/delete-account';

  // Dashboard & Overview
  static const String dashboardSummary = '/dashboard/summary';
  static const String todaysFocus = '/dashboard/focus';

  // Habits
  static const String habits = '/habits';
  static String habitDetail(String id) => '/habits/$id';
  static String toggleHabit(String id) => '/habits/$id/toggle';
  static String habitHistory(String id) => '/habits/$id/history';

  // Tasks & Todos
  static const String tasks = '/tasks';
  static String taskDetail(String id) => '/tasks/$id';
  static String updateTaskStatus(String id) => '/tasks/$id/status';

  // Routines (Morning, Evening, Work, etc.)
  static const String routines = '/routines';
  static String routineDetail(String id) => '/routines/$id';
  static String completeRoutineStep(String routineId, String stepId) =>
      '/routines/$routineId/steps/$stepId/complete';

  // Analytics & Insights
  static const String analyticsDaily = '/analytics/daily';
  static const String analyticsWeekly = '/analytics/weekly';
  static const String lifeMetrics = '/analytics/metrics';

  // Cloud Sync & Backup
  static const String syncPush = '/sync/push';
  static const String syncPull = '/sync/pull';
}
