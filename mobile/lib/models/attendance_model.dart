class StudentDetail {
  final int id;
  final String firstName;
  final String lastName;
  final String codeMassar;
  final String field;
  final String createdAt;

  StudentDetail({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.codeMassar,
    required this.field,
    required this.createdAt,
  });

  factory StudentDetail.fromJson(Map<String, dynamic> json) {
    return StudentDetail(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      codeMassar: json['code_massar'] as String? ?? '',
      field: json['field'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'code_massar': codeMassar,
        'field': field,
        'created_at': createdAt,
      };

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }
}

class AttendanceModel {
  final int id;
  final int student;
  final int session;
  final String validationTime;
  final String? ipAddress;
  final String deviceId;
  final StudentDetail? studentDetail;

  AttendanceModel({
    required this.id,
    required this.student,
    required this.session,
    required this.validationTime,
    this.ipAddress,
    required this.deviceId,
    this.studentDetail,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as int,
      student: json['student'] as int,
      session: json['session'] as int,
      validationTime: json['validation_time'] as String? ?? '',
      ipAddress: json['ip_address'] as String?,
      deviceId: json['device_id'] as String? ?? '',
      studentDetail: json['student_detail'] != null
          ? StudentDetail.fromJson(
              json['student_detail'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student': student,
        'session': session,
        'validation_time': validationTime,
        'ip_address': ipAddress,
        'device_id': deviceId,
        if (studentDetail != null)
          'student_detail': studentDetail!.toJson(),
      };

  /// Parses [validationTime] as a local [DateTime]. Returns null on parse failure.
  DateTime? get validationDateTime {
    try {
      return DateTime.parse(validationTime).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// A human-readable formatted validation time, e.g. "2025-05-01  14:32:05".
  String get formattedValidationTime {
    final dt = validationDateTime;
    if (dt == null) return validationTime;
    final pad = (int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)}  '
        '${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
  }

  AttendanceModel copyWith({
    int? id,
    int? student,
    int? session,
    String? validationTime,
    String? ipAddress,
    String? deviceId,
    StudentDetail? studentDetail,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      student: student ?? this.student,
      session: session ?? this.session,
      validationTime: validationTime ?? this.validationTime,
      ipAddress: ipAddress ?? this.ipAddress,
      deviceId: deviceId ?? this.deviceId,
      studentDetail: studentDetail ?? this.studentDetail,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AttendanceModel(id: $id, student: $student, session: $session, '
      'validationTime: $validationTime)';
}
