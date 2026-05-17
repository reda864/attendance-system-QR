import 'package:flutter/foundation.dart';

import '../models/auth_model.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../services/connectivity_service.dart';

enum AttendanceValidationStatus {
  idle,
  loading,
  success,
  failure,
}

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _attendanceService;
  final ConnectivityService _connectivityService;

  AttendanceProvider({
    AttendanceService? attendanceService,
    ConnectivityService? connectivityService,
  })  : _attendanceService = attendanceService ?? AttendanceService(),
        _connectivityService = connectivityService ?? ConnectivityService();

  // ─── QR State ─────────────────────────────────────────────────────────────
  String? _scannedQrToken;
  bool _qrScanned = false;

  // ─── Validation State ─────────────────────────────────────────────────────
  AttendanceValidationStatus _validationStatus =
      AttendanceValidationStatus.idle;
  AttendanceResult? _lastResult;
  AttendanceSuccessPayload? _successPayload;
  String? _errorTitle;
  String? _errorMessage;
  AttendanceErrorType? _errorType;

  // ─── History State ────────────────────────────────────────────────────────
  List<AttendanceModel> _attendanceHistory = [];
  bool _historyLoading = false;
  bool _historyError = false;
  String? _historyErrorMessage;

  // ─── Form pre-fill ────────────────────────────────────────────────────────
  String _prefillFirstName = '';
  String _prefillLastName = '';
  String _prefillCodeMassar = '';

  // ─── Getters: QR ──────────────────────────────────────────────────────────
  String? get scannedQrToken => _scannedQrToken;
  bool get qrScanned => _qrScanned;

  // ─── Getters: Validation ──────────────────────────────────────────────────
  AttendanceValidationStatus get validationStatus => _validationStatus;
  AttendanceResult? get lastResult => _lastResult;
  AttendanceSuccessPayload? get successPayload => _successPayload;
  String? get errorTitle => _errorTitle;
  String? get errorMessage => _errorMessage;
  AttendanceErrorType? get errorType => _errorType;

  bool get isLoading =>
      _validationStatus == AttendanceValidationStatus.loading;
  bool get isSuccess =>
      _validationStatus == AttendanceValidationStatus.success;
  bool get isFailure =>
      _validationStatus == AttendanceValidationStatus.failure;

  // ─── Getters: History ─────────────────────────────────────────────────────
  List<AttendanceModel> get attendanceHistory =>
      List.unmodifiable(_attendanceHistory);
  bool get historyLoading => _historyLoading;
  bool get historyError => _historyError;
  String? get historyErrorMessage => _historyErrorMessage;

  // ─── Getters: Pre-fill ────────────────────────────────────────────────────
  String get prefillFirstName => _prefillFirstName;
  String get prefillLastName => _prefillLastName;
  String get prefillCodeMassar => _prefillCodeMassar;

  // ─── QR Actions ───────────────────────────────────────────────────────────

  /// Called by the QR scanner screen when a valid token is detected.
  void setScannedToken(String token) {
    _scannedQrToken = token.trim();
    _qrScanned = true;
    // Reset any previous validation result when a new QR is scanned
    _validationStatus = AttendanceValidationStatus.idle;
    _lastResult = null;
    _successPayload = null;
    _errorTitle = null;
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }

  /// Clears the current QR token (e.g. when navigating back to scanner).
  void clearScannedToken() {
    _scannedQrToken = null;
    _qrScanned = false;
    notifyListeners();
  }

  // ─── Pre-fill Actions ─────────────────────────────────────────────────────

  /// Pre-fills student info (called when user is already authenticated).
  void prefillStudentInfo({
    required String firstName,
    required String lastName,
    required String codeMassar,
  }) {
    _prefillFirstName = firstName;
    _prefillLastName = lastName;
    _prefillCodeMassar = codeMassar;
    notifyListeners();
  }

  void clearPrefill() {
    _prefillFirstName = '';
    _prefillLastName = '';
    _prefillCodeMassar = '';
    notifyListeners();
  }

  // ─── Validation Action ────────────────────────────────────────────────────

  /// Sends the attendance validation request to the backend.
  ///
  /// [qrToken] – UUID from the scanned QR code.
  /// [firstName], [lastName], [codeMassar] – student identity fields.
  Future<AttendanceResult> validateAttendance({
    required String qrToken,
    required String firstName,
    required String lastName,
    required String codeMassar,
  }) async {
    // Check connectivity first
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      final result = AttendanceResult.failure(
        message: 'No internet connection.',
        type: AttendanceErrorType.noInternet,
      );
      _applyResult(result);
      return result;
    }

    _validationStatus = AttendanceValidationStatus.loading;
    _lastResult = null;
    _errorTitle = null;
    _errorMessage = null;
    _errorType = null;
    notifyListeners();

    final request = ValidateAttendanceRequest(
      qrToken: qrToken,
      firstName: firstName,
      lastName: lastName,
      codeMassar: codeMassar,
    );

    final result = await _attendanceService.validateAttendance(request);
    _applyResult(result);
    return result;
  }

  // ─── History Actions ──────────────────────────────────────────────────────

  /// Loads attendance history for the current student.
  Future<void> loadAttendanceHistory({bool refresh = false}) async {
    if (_historyLoading) return;

    if (refresh) {
      _attendanceHistory.clear();
    }

    _historyLoading = true;
    _historyError = false;
    _historyErrorMessage = null;
    notifyListeners();

    try {
      final isConnected = await _connectivityService.isConnected();
      if (!isConnected) {
        _historyError = true;
        _historyErrorMessage = 'No internet connection.';
        _historyLoading = false;
        notifyListeners();
        return;
      }

      final rawList = await _attendanceService.fetchMyAttendance();
      _attendanceHistory = rawList
          .map((json) => AttendanceModel.fromJson(json))
          .toList();
    } catch (e) {
      _historyError = true;
      _historyErrorMessage = e.toString();
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  // ─── Reset ────────────────────────────────────────────────────────────────

  /// Resets validation state to idle (e.g. when returning to home screen).
  void resetValidation() {
    _validationStatus = AttendanceValidationStatus.idle;
    _lastResult = null;
    _successPayload = null;
    _errorTitle = null;
    _errorMessage = null;
    _errorType = null;
    _scannedQrToken = null;
    _qrScanned = false;
    notifyListeners();
  }

  /// Full reset — clears everything including history.
  void resetAll() {
    resetValidation();
    _attendanceHistory.clear();
    _historyLoading = false;
    _historyError = false;
    _historyErrorMessage = null;
    _prefillFirstName = '';
    _prefillLastName = '';
    _prefillCodeMassar = '';
    notifyListeners();
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  void _applyResult(AttendanceResult result) {
    _lastResult = result;
    if (result.success) {
      _validationStatus = AttendanceValidationStatus.success;
      _successPayload = result.payload;
      _errorTitle = null;
      _errorMessage = null;
      _errorType = null;
    } else {
      _validationStatus = AttendanceValidationStatus.failure;
      _successPayload = null;
      _errorType = result.errorType;
      _errorTitle = result.errorTitle;
      _errorMessage = result.errorMessage;
    }
    notifyListeners();
  }
}
