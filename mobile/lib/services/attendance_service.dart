import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

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

  Future<AttendanceResult> validateAttendance(
    ValidateAttendanceRequest request, {
    double? latitude,
    double? longitude,
  }) async {
    return _submitValidation(
      endpoint: AppConstants.validateAttendanceEndpoint,
      payload: {
        'qr_token': request.qrToken,
        'first_name': request.firstName.trim(),
        'last_name': request.lastName.trim(),
        'code_massar': request.codeMassar.trim(),
        'device_id': request.deviceId,
        'device_fingerprint': request.deviceFingerprint,
        'device_info': request.deviceInfo,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
  }

  Future<AttendanceResult> validateAttendanceFromApp({
    required String qrToken,
    double? latitude,
    double? longitude,
  }) async {
    final deviceId = await _getDeviceId();
    final deviceInfo = await _getDeviceInfo();
    final fingerprint = _computeFingerprint(deviceId, deviceInfo);

    return _submitValidation(
      endpoint: AppConstants.validateAppAttendanceEndpoint,
      payload: {
        'qr_token': qrToken,
        'device_id': deviceId,
        'device_fingerprint': fingerprint,
        'device_info': deviceInfo,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
  }

  Future<AttendanceResult> _submitValidation({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _client.post(endpoint, data: payload);
      final statusCode = response.statusCode ?? 0;

      if (statusCode == 200 || statusCode == 201) {
        final body = _responseBodyAsMap(response.data);
        if (body == null) {
          return AttendanceResult.failure(
            message:
                'Réponse serveur invalide après validation. Vérifiez l’URL de l’API.',
            type: AttendanceErrorType.unknown,
          );
        }
        try {
          return AttendanceResult.success(body);
        } catch (e, st) {
          debugPrint('[AttendanceService] Parse error: $e\n$st\nbody=$body');
          return AttendanceResult.failure(
            message: 'Réponse serveur illisible.',
            type: AttendanceErrorType.unknown,
          );
        }
      }

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
        message: 'Le serveur met trop de temps à répondre. Réessayez.',
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

  Future<({double latitude, double longitude})?> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return (latitude: position.latitude, longitude: position.longitude);
  }

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

  Future<({String deviceId, String deviceInfo, String fingerprint})>
      getDeviceMetadata() async {
    final deviceId = await _getDeviceId();
    final deviceInfo = await _getDeviceInfo();
    final fingerprint = _computeFingerprint(deviceId, deviceInfo);
    return (
      deviceId: deviceId,
      deviceInfo: deviceInfo,
      fingerprint: fingerprint,
    );
  }

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
    } catch (_) {}
    return '';
  }

  Future<String> _getDeviceInfo() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _deviceInfo.androidInfo;
        return jsonEncode({
          'platform': 'android',
          'brand': info.brand,
          'model': info.model,
          'version': info.version.release,
        });
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _deviceInfo.iosInfo;
        return jsonEncode({
          'platform': 'ios',
          'model': info.model,
          'system': info.systemVersion,
        });
      }
    } catch (_) {}
    return jsonEncode({'platform': Platform.operatingSystem});
  }

  String _computeFingerprint(String deviceId, String deviceInfo) {
    final digest = sha256.convert(utf8.encode('$deviceId|$deviceInfo'));
    return digest.toString();
  }
}
