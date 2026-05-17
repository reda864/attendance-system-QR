import 'package:flutter/foundation.dart';

import '../models/auth_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/app_exceptions.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  // ─── State ────────────────────────────────────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _isLoggingOut = false;

  // ─── Getters ──────────────────────────────────────────────────────────────
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoggingOut => _isLoggingOut;

  bool get isLoggedIn =>
      _status == AuthStatus.authenticated && _user != null;

  // ─── Initialise (called at app startup) ──────────────────────────────────

  /// Checks SharedPreferences for a stored session and restores it.
  Future<void> init() async {
    _setStatus(AuthStatus.loading);
    try {
      final loggedIn = await _authService.isLoggedIn();
      if (loggedIn) {
        final storedUser = await _authService.getStoredUser();
        if (storedUser != null) {
          _user = storedUser;
          _setStatus(AuthStatus.authenticated);
          // Silently refresh user data in the background
          _refreshUserInBackground();
        } else {
          // Token exists but no user data — fetch from backend
          await _fetchMe();
        }
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (_) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  // ─── Login ─────────────────────────────────────────────────────────────────

  /// Authenticates with [email] and [password].
  /// Returns `true` on success, `false` on failure (error is in [errorMessage]).
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _clearError();
    _setStatus(AuthStatus.loading);

    try {
      final authResponse = await _authService.login(
        email: email,
        password: password,
      );
      _user = authResponse.user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } on UnauthorizedException {
      _errorMessage = 'Invalid email or password. Please try again.';
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } on NetworkException {
      _errorMessage = 'No internet connection. Please check your network.';
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } on TimeoutException {
      _errorMessage = 'Request timed out. Please try again.';
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────────────

  /// Clears the session and marks the user as unauthenticated.
  Future<void> logout() async {
    _isLoggingOut = true;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (_) {
      // Even if logout fails on the server/storage, clear local state
    } finally {
      _user = null;
      _errorMessage = null;
      _isLoggingOut = false;
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  // ─── Update stored user ────────────────────────────────────────────────────

  /// Updates the in-memory and persisted [UserModel].
  Future<void> updateUser(UserModel updatedUser) async {
    _user = updatedUser;
    await _authService.updateStoredUser(updatedUser);
    notifyListeners();
  }

  // ─── Clear error ───────────────────────────────────────────────────────────

  void clearError() => _clearError();

  // ─── Private helpers ───────────────────────────────────────────────────────

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<void> _fetchMe() async {
    try {
      _user = await _authService.fetchMe();
      _setStatus(AuthStatus.authenticated);
    } on UnauthorizedException {
      await _authService.logout();
      _setStatus(AuthStatus.unauthenticated);
    } catch (_) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<void> _refreshUserInBackground() async {
    try {
      final freshUser = await _authService.fetchMe();
      _user = freshUser;
      notifyListeners();
    } catch (_) {
      // Silently ignore background refresh failures
    }
  }
}
