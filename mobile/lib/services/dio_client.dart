import 'dart:async';
import 'dart:io' hide TimeoutException;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/app_exceptions.dart';

class DioClient {
  static DioClient? _instance;
  late final Dio _dio;

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 600,
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_dio),
      _LoggingInterceptor(),
    ]);
  }

  factory DioClient() {
    _instance ??= DioClient._internal();
    return _instance!;
  }

  Dio get dio => _dio;

  // ─── Convenience wrappers ────────────────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } on SocketException {
      throw const NetworkException();
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } on SocketException {
      throw const NetworkException();
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } on SocketException {
      throw const NetworkException();
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } on SocketException {
      throw const NetworkException();
    }
  }

  // ─── Exception mapping ───────────────────────────────────────────────────

  AppException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final data = e.response?.data;
        String? message;

        if (data is Map<String, dynamic>) {
          message = data['error'] as String? ??
              data['detail'] as String? ??
              data['message'] as String?;

          // Handle DRF validation errors (non_field_errors list)
          if (message == null && data['non_field_errors'] is List) {
            final errors = data['non_field_errors'] as List;
            if (errors.isNotEmpty) message = errors.first.toString();
          }
        } else if (data is String && data.isNotEmpty) {
          message = data;
        }

        return exceptionFromStatusCode(statusCode, message);

      case DioExceptionType.cancel:
        return const AppException('Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const AppException('SSL certificate error.');

      case DioExceptionType.unknown:
      default:
        if (e.error is SocketException) return const NetworkException();
        return UnknownException(e.message ?? 'Unknown error.');
    }
  }

  /// Dispose / reset the singleton (useful for testing).
  static void reset() => _instance = null;
}

// ─── Auth Interceptor ──────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingQueue = [];

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for login and refresh endpoints
    final path = options.path;
    if (path.contains('/auth/login/') || path.contains('/auth/refresh/')) {
      return handler.next(options);
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.accessTokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;

    // Only attempt refresh on 401, and not for the refresh endpoint itself
    if (response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/refresh/') &&
        !err.requestOptions.path.contains('/auth/login/')) {
      if (_isRefreshing) {
        // Queue the request until refresh completes
        final completer = _PendingRequest(err.requestOptions);
        _pendingQueue.add(completer);
        try {
          final retryResp = await completer.future;
          return handler.resolve(retryResp);
        } catch (_) {
          return handler.next(err);
        }
      }

      _isRefreshing = true;

      try {
        final newToken = await _refreshToken();
        if (newToken != null) {
          // Retry the original request with the new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final clonedRequest = await _dio.fetch(err.requestOptions);

          // Flush the pending queue
          for (final pending in _pendingQueue) {
            try {
              pending.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';
              final r = await _dio.fetch(pending.requestOptions);
              pending.complete(r);
            } catch (e) {
              pending.completeError(e);
            }
          }
          _pendingQueue.clear();
          _isRefreshing = false;

          return handler.resolve(clonedRequest);
        }
      } catch (_) {
        // Refresh failed → clear tokens and signal logout
        await _clearTokens();
      } finally {
        _isRefreshing = false;
        for (final pending in _pendingQueue) {
          pending.completeError(
            const UnauthorizedException('Session expired. Please login again.'),
          );
        }
        _pendingQueue.clear();
      }
    }

    return handler.next(err);
  }

  Future<String?> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _dio.post(
        AppConstants.refreshEndpoint,
        data: {'refresh': refreshToken},
        options: Options(
          headers: {'Authorization': null},
          extra: {'skipAuth': true},
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final newAccess = response.data['access'] as String?;
        if (newAccess != null) {
          await prefs.setString(AppConstants.accessTokenKey, newAccess);
          return newAccess;
        }
      }
    } catch (_) {
      // Refresh request failed
    }
    return null;
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userDataKey);
  }
}

// ─── Pending Request Helper ────────────────────────────────────────────────

class _PendingRequest {
  final RequestOptions requestOptions;
  final Completer<Response> _completer = Completer<Response>();

  _PendingRequest(this.requestOptions);

  Future<Response> get future => _completer.future;

  void complete(Response response) {
    if (!_completer.isCompleted) _completer.complete(response);
  }

  void completeError(Object error) {
    if (!_completer.isCompleted) _completer.completeError(error);
  }
}

// ─── Logging Interceptor ───────────────────────────────────────────────────

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print(
        '[DIO] --> ${options.method.toUpperCase()} '
        '${options.baseUrl}${options.path}',
      );
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print(
        '[DIO] <-- ${response.statusCode} '
        '${response.requestOptions.method.toUpperCase()} '
        '${response.requestOptions.path}',
      );
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print(
        '[DIO] !! ERROR ${err.response?.statusCode} '
        '${err.requestOptions.method.toUpperCase()} '
        '${err.requestOptions.path}: ${err.message}',
      );
      return true;
    }());
    handler.next(err);
  }
}
