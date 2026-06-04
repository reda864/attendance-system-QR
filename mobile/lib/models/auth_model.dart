import '../l10n/app_strings.dart';
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
        return 'Code QR expiré';
      case AttendanceErrorType.alreadyValidated:
        return 'Déjà enregistré';
      case AttendanceErrorType.invalidQr:
        return 'Code QR invalide';
      case AttendanceErrorType.sessionClosed:
        return 'Séance fermée';
      case AttendanceErrorType.studentNotFound:
        return 'Étudiant introuvable';
      case AttendanceErrorType.nameMismatch:
        return 'Nom incorrect';
      case AttendanceErrorType.noInternet:
        return 'Pas de connexion';
      case AttendanceErrorType.timeout:
        return 'Délai dépassé';
      case AttendanceErrorType.unknown:
        return AppStrings.errorOccurred;
    }
  }

  String get displayMessage {
    switch (this) {
      case AttendanceErrorType.expired:
        return 'Ce code QR a expiré. Demandez à votre enseignant d\'en générer un nouveau.';
      case AttendanceErrorType.alreadyValidated:
        return 'Votre présence est déjà enregistrée pour cette séance.';
      case AttendanceErrorType.invalidQr:
        return 'Code QR invalide. Scannez le code affiché par votre enseignant.';
      case AttendanceErrorType.sessionClosed:
        return 'Cette séance n\'est plus active. L\'enregistrement est fermé.';
      case AttendanceErrorType.studentNotFound:
        return 'Code Massar introuvable. Contactez votre enseignant.';
      case AttendanceErrorType.nameMismatch:
        return 'Le nom saisi ne correspond pas aux registres. Vérifiez vos informations.';
      case AttendanceErrorType.noInternet:
        return AppStrings.noInternet;
      case AttendanceErrorType.timeout:
        return AppStrings.requestTimeout;
      case AttendanceErrorType.unknown:
        return AppStrings.unexpectedError;
    }
  }

  static AttendanceErrorType fromBackendMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('expired') || lower.contains('expiré')) {
      return AttendanceErrorType.expired;
    }
    if (lower.contains('already') ||
        lower.contains('déjà') ||
        lower.contains('duplicate')) {
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
    if (lower.contains('zone') ||
        lower.contains('localisation') ||
        lower.contains('gps')) {
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

  String get errorTitle => errorType?.displayTitle ?? AppStrings.errorOccurred;
  String get errorMessage {
    final raw = rawErrorMessage?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return errorType?.displayMessage ?? AppStrings.unexpectedError;
  }
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
    throw FormatException('Champ $field invalide dans la réponse : $value');
  }

  DateTime? get validationDateTime {
    try {
      return DateTime.parse(validationTime).toLocal();
    } catch (_) {
      return null;
    }
  }

  String get formattedValidationTime {
    final dt = validationDateTime;
    if (dt == null) return validationTime;
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)}  '
        '${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
  }
}
