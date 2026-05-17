import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../models/auth_model.dart';
import '../utils/app_exceptions.dart';
import 'dio_client.dart';

class AttendanceService {
  final DioClient _client;
  final DeviceInfoPlugin _deviceInfo;

  AttendanceService({DioClient? client, DeviceInfoPlugin? deviceInfo})
      : _client = client ?? DioClient(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  // ─── Validate Attendance ─────────────────────────────────────────────────

  /// Sends attendance validation to the backend.
  /// Returns an [AttendanceResult] — never throws directly.
  Future<AttendanceResult> validateAttendance(
    ValidateAttendanceRequest request,
  ) async {
    try {
      final deviceId = await _getDeviceId();

      final payload = {
        'qr_token': request.qrToken,
        'first_name': request.firstName.trim(),
        'last_name': request.lastName.trim(),
        'code_massar': request.codeMassar.trim(),
        'device_id': deviceId,
      };

      final response = await _client.post(
        AppConstants.validateAttendanceEndpoint,
        data: payload,
      );

      final statusCode = response.statusCode ?? 0;

      if (statusCode == 200 || statusCode == 201) {
        return AttendanceResult.success(
          response.data as Map<String, dynamic>,
        );
      }

      // Non-2xx without a thrown exception (edge case from validateStatus)
      final data = response.data;
      String message = 'Attendance validation failed.';
      if (data is Map<String, dynamic>) {
        message = data['error'] as String? ??
            data['detail'] as String? ??
            message;
      }
      return AttendanceResult.failure(message: message);
    } on NetworkException {
      return AttendanceResult.failure(
        message: 'No internet connection.',
        type: AttendanceErrorType.noInternet,
      );
    } on TimeoutException {
      return AttendanceResult.failure(
        message: 'Request timed out.',
        type: AttendanceErrorType.timeout,
      );
    } on ValidationException catch (e) {
      return AttendanceResult.failure(message: e.message);
    } on AppException catch (e) {
      return AttendanceResult.failure(message: e.message);
    } catch (e) {
      return AttendanceResult.failure(
        message: 'An unexpected error occurred.',
        type: AttendanceErrorType.unknown,
      );
    }
  }

  // ─── My Attendance History ────────────────────────────────────────────────

  /// Fetches the attendance history list for the logged-in student.
  /// Returns a list of raw JSON maps, or throws on network / auth errors.
  Future<List<Map<String, dynamic>>> fetchMyAttendance({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        AppConstants.myAttendanceEndpoint,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        // DRF paginated response
        if (data is Map<String, dynamic> && data['results'] is List) {
          return (data['results'] as List).cast<Map<String, dynamic>>();
        }
      }
      return [];
    } on NetworkException {
      rethrow;
    } on AppException {
      rethrow;
    } catch (_) {
      return [];
    }
  }

  // ─── Device ID ────────────────────────────────────────────────────────────

  Future<String> _getDeviceId() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _deviceInfo.androidInfo;
        return info.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _deviceInfo.iosInfo;
        return info.identifierForVendor ?? '';
      }
    } catch (_) {
      // Return empty string on failure — backend accepts it
    }
    return '';
  }
}
