import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../providers/attendance_provider.dart';
import '../utils/validators.dart';

class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  void init(void Function(String token) onToken) {
    _subscription?.cancel();
    _subscription = _appLinks.uriLinkStream.listen((uri) {
      final token = extractTokenFromUri(uri);
      if (token != null) onToken(token);
    });

    _appLinks.getInitialLink().then((uri) {
      if (uri == null) return;
      final token = extractTokenFromUri(uri);
      if (token != null) onToken(token);
    });
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  static String? extractTokenFromUri(Uri uri) {
    if (uri.scheme == AppConstants.appDeepLinkScheme && uri.host == 'attend') {
      final token = uri.queryParameters['token']?.trim();
      if (token != null && Validators.isValidQrToken(token)) return token;
    }

    if (uri.path.contains('attend')) {
      final token = uri.queryParameters['token']?.trim();
      if (token != null && Validators.isValidQrToken(token)) return token;
    }

    return null;
  }

  static String? extractTokenFromRaw(String rawValue) {
    final value = rawValue.trim();
    if (Validators.isValidQrToken(value)) return value;

    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    return extractTokenFromUri(uri);
  }
}

Future<void> handleDeepLinkToken(
  BuildContext context,
  String token, {
  required bool isAuthenticated,
  required bool hasStudentProfile,
}) async {
  final attendanceProvider = context.read<AttendanceProvider>();
  attendanceProvider.setScannedToken(token);

  if (isAuthenticated && hasStudentProfile) {
    final result = await attendanceProvider.validateFromApp(qrToken: token);
    if (!context.mounted) return;

    if (result.success) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppConstants.routeSuccess,
        (route) => route.settings.name == AppConstants.routeHome,
      );
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppConstants.routeError,
        (route) => route.settings.name == AppConstants.routeHome,
      );
    }
    return;
  }

  if (isAuthenticated) {
    Navigator.of(context).pushNamed(AppConstants.routeValidation);
  } else {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppConstants.routeLogin,
      (_) => false,
    );
  }
}
