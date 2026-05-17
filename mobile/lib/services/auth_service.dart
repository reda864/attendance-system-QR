import 'dart:convert';
import 'dart:io' hide TimeoutException;

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart';
import '../utils/app_exceptions.dart';
import 'dio_client.dart';

class AuthService {
  final DioClient _client;

  AuthService({DioClient? client}) : _client = client ?? DioClient();

  // ─── Login ──────────────────────────────────────────────────────────────

  /// Authenticates the user with [email] and [password].
  /// On success, persists JWT tokens and user data to SharedPreferences.
  /// Throws a typed [AppException] on failure.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      AppConstants.loginEndpoint,
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final statusCode = response.statusCode ?? 0;

    if (statusCode == 200 || statusCode == 201) {
      final data = response.data as Map<String, dynamic>;
      final authResponse = AuthResponse.fromJson(data);
      await _persistSession(authResponse);
      return authResponse;
    }

    // Error responses are usually already thrown by DioClient interceptors,
    // but handle any edge-case here:
    final data = response.data;
    String message = 'Login failed.';
    if (data is Map<String, dynamic>) {
      message = data['detail'] as String? ??
          data['error'] as String? ??
          data['non_field_errors']?.toString() ??
          message;
    }
    throw exceptionFromStatusCode(statusCode, message);
  }

  // ─── Logout ─────────────────────────────────────────────────────────────

  /// Clears all stored session data from SharedPreferences.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(AppConstants.accessTokenKey),
      prefs.remove(AppConstants.refreshTokenKey),
      prefs.remove(AppConstants.userDataKey),
    ]);
  }

  // ─── Session Checks ─────────────────────────────────────────────────────

  /// Returns `true` if a valid access token is stored.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Fetches the stored [UserModel] from local storage, or `null` if absent.
  Future<UserModel?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.userDataKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Returns the stored access JWT token, or `null`.
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.accessTokenKey);
  }

  /// Returns the stored refresh JWT token, or `null`.
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.refreshTokenKey);
  }

  // ─── Refresh ─────────────────────────────────────────────────────────────

  /// Attempts a token refresh using the stored refresh token.
  /// Returns the new access token string on success, `null` on failure.
  Future<String?> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _client.post(
        AppConstants.refreshEndpoint,
        data: {'refresh': refreshToken},
      );

      if ((response.statusCode ?? 0) == 200) {
        final newAccess = (response.data as Map<String, dynamic>)['access']
            as String?;
        if (newAccess != null) {
          await prefs.setString(AppConstants.accessTokenKey, newAccess);
          return newAccess;
        }
      }
    } catch (_) {
      // Swallow and return null — caller decides what to do
    }
    return null;
  }

  // ─── Fetch /me ─────────────────────────────────────────────────────────

  /// Fetches the currently authenticated user's profile from the backend
  /// and updates the stored user data.
  Future<UserModel> fetchMe() async {
    final response = await _client.get(AppConstants.meEndpoint);

    final statusCode = response.statusCode ?? 0;
    if (statusCode == 200) {
      final user =
          UserModel.fromJson(response.data as Map<String, dynamic>);
      await _updateStoredUser(user);
      return user;
    }

    throw exceptionFromStatusCode(
      statusCode,
      'Failed to fetch user profile.',
    );
  }

  // ─── Update stored user ─────────────────────────────────────────────────

  /// Persists an updated [UserModel] to SharedPreferences.
  Future<void> updateStoredUser(UserModel user) => _updateStoredUser(user);

  // ─── Private helpers ────────────────────────────────────────────────────

  Future<void> _persistSession(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(AppConstants.accessTokenKey, authResponse.access),
      prefs.setString(AppConstants.refreshTokenKey, authResponse.refresh),
      prefs.setString(
        AppConstants.userDataKey,
        jsonEncode(authResponse.user.toJson()),
      ),
    ]);
  }

  Future<void> _updateStoredUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.userDataKey,
      jsonEncode(user.toJson()),
    );
  }
}
