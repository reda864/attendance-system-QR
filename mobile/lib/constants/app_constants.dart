import 'package:flutter/foundation.dart';

class AppConstants {
  // ─── API Base URL ─────────────────────────────────────────────────────────
  // Production (Render, Railway, etc.) — set this when the API is not on your PC:
  //   flutter run --dart-define=API_BASE_URL=https://YOUR-SERVICE.onrender.com/api/v1
  // Physical device on the same Wi‑Fi as your PC (default below).
  // Android emulator only: use host loopback alias:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
  // Different PC IP:
  //   flutter run --dart-define=DEV_HOST=192.168.x.x
  //   or --dart-define=API_BASE_URL=http://192.168.x.x:8000/api/v1
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// LAN IP of the machine running Django (must match ALLOWED_HOSTS in backend).
  static const String devHost = String.fromEnvironment(
    'DEV_HOST',
    defaultValue: '192.168.1.15',
  );

  static const int apiPort = 8000;

  static String get baseUrl {
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) {
      return override.endsWith('/') ? override.substring(0, override.length - 1) : override;
    }
    if (kIsWeb) return 'http://localhost:$apiPort/api/v1';
    // Real phones cannot use localhost or 10.0.2.2 — use your PC's LAN IP.
    return 'http://$devHost:$apiPort/api/v1';
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
  // Render free tier can cold-start 30–60s; local Wi‑Fi may be slow too.
  static const int connectTimeout = 60000;
  static const int receiveTimeout = 60000;

  // ─── Named routes ─────────────────────────────────────────────────────────
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeHome = '/home';
  static const String routeScanner = '/scanner';
  static const String routeValidation = '/validation';
  static const String routeSuccess = '/success';
  static const String routeError = '/error';

  // ─── Misc ─────────────────────────────────────────────────────────────────
  static const String appName = 'PrésenceQR';
  static const String appVersion = '1.0.0';
}
