import 'dart:convert';

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
        final body = _responseBodyAsMap(response.data);
        if (body == null) {
          debugPrint(
            '[AttendanceService] Success status $statusCode but invalid body: '
            '${response.data.runtimeType}',
          );
          return AttendanceResult.failure(
            message:
                'Réponse serveur invalide après validation. Vérifiez l’URL de l’API (Render / PC).',
            type: AttendanceErrorType.unknown,
          );
        }
        try {
          return AttendanceResult.success(body);
        } catch (e, st) {
          debugPrint('[AttendanceService] Parse error: $e\n$st\nbody=$body');
          return AttendanceResult.failure(
            message:
                'Réponse serveur illisible. Mettez à jour l’application ou contactez le support.',
            type: AttendanceErrorType.unknown,
          );
        }
      }

      // Non-2xx without a thrown exception (edge case from validateStatus)
      final data = _responseBodyAsMap(response.data);
      String message = 'La validation de la présence a échoué.';
      if (data != null) {
        message = data['error']?.toString() ??
            data['detail']?.toString() ??
            message;
      }
      return AttendanceResult.failure(message: message);
    } on NetworkException {
      return AttendanceResult.failure(
        message: 'Pas de connexion Internet.',
        type: AttendanceErrorType.noInternet,
      );
    } on TimeoutException {
      return AttendanceResult.failure(
        message:
            'Le serveur met trop de temps à répondre (Render peut mettre ~1 min au réveil). Réessayez dans un instant.',
        type: AttendanceErrorType.timeout,
      );
    } on ValidationException catch (e) {
      return AttendanceResult.failure(message: e.message);
    } on AppException catch (e) {
      return AttendanceResult.failure(message: e.message);
    } catch (e) {
      return AttendanceResult.failure(
        message: 'Une erreur inattendue s\'est produite.',
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

  Map<String, dynamic>? _responseBodyAsMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

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
