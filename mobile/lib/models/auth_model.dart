import 'user_model.dart';

// ─── Auth Response ─────────────────────────────────────────────────────────

class AuthResponse {
  final String access;
  final String refresh;
  final UserModel user;

  AuthResponse({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'access': access,
        'refresh': refresh,
        'user': user.toJson(),
      };

  @override
  String toString() =>
      'AuthResponse(access: [hidden], refresh: [hidden], user: $user)';
}

// ─── Token Refresh Response ────────────────────────────────────────────────

class TokenRefreshResponse {
  final String access;

  TokenRefreshResponse({required this.access});

  factory TokenRefreshResponse.fromJson(Map<String, dynamic> json) {
    return TokenRefreshResponse(access: json['access'] as String);
  }
}

// ─── Validate Attendance Request ───────────────────────────────────────────

class ValidateAttendanceRequest {
  final String qrToken;
  final String firstName;
  final String lastName;
  final String codeMassar;
  final String deviceId;
  final String deviceFingerprint;
  final String deviceInfo;

  ValidateAttendanceRequest({
    required this.qrToken,
    required this.firstName,
    required this.lastName,
    required this.codeMassar,
    this.deviceId = '',
    this.deviceFingerprint = '',
    this.deviceInfo = '',
  });

  Map<String, dynamic> toJson() => {
        'qr_token': qrToken,
        'first_name': firstName,
        'last_name': lastName,
        'code_massar': codeMassar,
        'device_id': deviceId,
      };

  @override
  String toString() =>
      'ValidateAttendanceRequest(qrToken: $qrToken, '
      'name: $firstName $lastName, codeMassar: $codeMassar)';
}

// ─── Validate Attendance Result ────────────────────────────────────────────

enum AttendanceErrorType {
  expired,
  alreadyValidated,
  invalidQr,
  sessionClosed,
  studentNotFound,
  nameMismatch,
  noInternet,
  timeout,
  unknown,
}

extension AttendanceErrorTypeX on AttendanceErrorType {
  String get displayTitle {
    switch (this) {
      case AttendanceErrorType.expired:
        return 'QR Code Expired';
      case AttendanceErrorType.alreadyValidated:
        return 'Already Registered';
      case AttendanceErrorType.invalidQr:
        return 'Invalid QR Code';
      case AttendanceErrorType.sessionClosed:
        return 'Session Closed';
      case AttendanceErrorType.studentNotFound:
        return 'Student Not Found';
      case AttendanceErrorType.nameMismatch:
        return 'Name Mismatch';
      case AttendanceErrorType.noInternet:
        return 'No Connection';
      case AttendanceErrorType.timeout:
        return 'Request Timed Out';
      case AttendanceErrorType.unknown:
        return 'Error Occurred';
    }
  }

  String get displayMessage {
    switch (this) {
      case AttendanceErrorType.expired:
        return 'This QR code has expired. Please ask your teacher to generate a new one.';
      case AttendanceErrorType.alreadyValidated:
        return 'Your attendance has already been recorded for this session.';
      case AttendanceErrorType.invalidQr:
        return 'The QR code is invalid. Please scan the correct teacher QR code.';
      case AttendanceErrorType.sessionClosed:
        return 'This session is no longer active. Attendance registration is closed.';
      case AttendanceErrorType.studentNotFound:
        return 'Your Code Massar was not found in the system. Please contact your teacher.';
      case AttendanceErrorType.nameMismatch:
        return 'The name you entered does not match our records. Please verify your information.';
      case AttendanceErrorType.noInternet:
        return 'No internet connection detected. Please check your network and try again.';
      case AttendanceErrorType.timeout:
        return 'The request timed out. Please check your connection and try again.';
      case AttendanceErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Maps a raw error string from the Django backend to a typed error.
  static AttendanceErrorType fromBackendMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('expired') || lower.contains('expiré')) {
      return AttendanceErrorType.expired;
    }
    if (lower.contains('already') || lower.contains('déjà')) {
      return AttendanceErrorType.alreadyValidated;
    }
    if (lower.contains('invalid qr') ||
        lower.contains('invalid token') ||
        lower.contains('invalide')) {
      return AttendanceErrorType.invalidQr;
    }
    if (lower.contains('no longer active') ||
        lower.contains('not active') ||
        lower.contains('plus active')) {
      return AttendanceErrorType.sessionClosed;
    }
    if (lower.contains('not found') || lower.contains('introuvable')) {
      return AttendanceErrorType.studentNotFound;
    }
    if (lower.contains('name does not match') ||
        lower.contains('mismatch') ||
        lower.contains('ne correspond pas')) {
      return AttendanceErrorType.nameMismatch;
    }
    if (lower.contains('zone') || lower.contains('localisation')) {
      return AttendanceErrorType.unknown;
    }
    return AttendanceErrorType.unknown;
  }
}

class AttendanceResult {
  final bool success;
  final AttendanceErrorType? errorType;
  final String? rawErrorMessage;
  final AttendanceSuccessPayload? payload;

  const AttendanceResult._({
    required this.success,
    this.errorType,
    this.rawErrorMessage,
    this.payload,
  });

  factory AttendanceResult.success(Map<String, dynamic> json) {
    return AttendanceResult._(
      success: true,
      payload: AttendanceSuccessPayload.fromJson(json),
    );
  }

  factory AttendanceResult.failure({
    required String message,
    AttendanceErrorType? type,
  }) {
    return AttendanceResult._(
      success: false,
      errorType: type ?? AttendanceErrorTypeX.fromBackendMessage(message),
      rawErrorMessage: message,
    );
  }

  String get errorTitle => errorType?.displayTitle ?? 'Error';
  String get errorMessage {
    final raw = rawErrorMessage?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return errorType?.displayMessage ?? 'An error occurred.';
  }

  @override
  String toString() => success
      ? 'AttendanceResult.success(payload: $payload)'
      : 'AttendanceResult.failure(type: $errorType, msg: $rawErrorMessage)';
}

// ─── Attendance Success Payload ────────────────────────────────────────────

class AttendanceSuccessPayload {
  final int id;
  final int student;
  final int session;
  final String validationTime;
  final String? ipAddress;
  final String deviceId;

  AttendanceSuccessPayload({
    required this.id,
    required this.student,
    required this.session,
    required this.validationTime,
    this.ipAddress,
    required this.deviceId,
  });

  factory AttendanceSuccessPayload.fromJson(Map<String, dynamic> json) {
    return AttendanceSuccessPayload(
      id: _readInt(json['id'], 'id'),
      student: _readInt(json['student'], 'student'),
      session: _readInt(json['session'], 'session'),
      validationTime: json['validation_time']?.toString() ?? '',
      ipAddress: json['ip_address']?.toString(),
      deviceId: json['device_id']?.toString() ?? '',
    );
  }

  static int _readInt(dynamic value, String field) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Invalid $field in attendance response: $value');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student': student,
        'session': session,
        'validation_time': validationTime,
        'ip_address': ipAddress,
        'device_id': deviceId,
      };

  /// Returns the validation time parsed to local [DateTime], or null.
  DateTime? get validationDateTime {
    try {
      return DateTime.parse(validationTime).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// A human-readable formatted validation time string.
  String get formattedValidationTime {
    final dt = validationDateTime;
    if (dt == null) return validationTime;
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)}  '
        '${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
  }

  @override
  String toString() =>
      'AttendanceSuccessPayload(id: $id, session: $session, '
      'validationTime: $validationTime)';
}
