import 'package:flutter/foundation.dart';

class AppConstants {
  // ─── API Base URL ─────────────────────────────────────────────────────────
  // Override for a physical device on the same Wi‑Fi as your PC:
  //   flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000/api/v1
  //
  // Defaults:
  //   Android emulator → 10.0.2.2 (host loopback)
  //   iOS simulator / desktop / web → localhost
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) {
      return override.endsWith('/') ? override.substring(0, override.length - 1) : override;
    }
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api/v1';
      default:
        return 'http://localhost:8000/api/v1';
    }
  }

  // ─── Endpoints ────────────────────────────────────────────────────────────
  static const String loginEndpoint = '/auth/login/';
  static const String refreshEndpoint = '/auth/refresh/';
  static const String meEndpoint = '/auth/me/';
  static const String validateAttendanceEndpoint = '/attendance/validate/';
  static const String myAttendanceEndpoint = '/attendance/my/';

  // ─── SharedPreferences keys ───────────────────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';

  // ─── HTTP timeouts (ms) ───────────────────────────────────────────────────
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 15000;

  // ─── Named routes ─────────────────────────────────────────────────────────
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeHome = '/home';
  static const String routeScanner = '/scanner';
  static const String routeValidation = '/validation';
  static const String routeSuccess = '/success';
  static const String routeError = '/error';

  // ─── Misc ─────────────────────────────────────────────────────────────────
  static const String appName = 'AttendQR';
  static const String appVersion = '1.0.0';
}
