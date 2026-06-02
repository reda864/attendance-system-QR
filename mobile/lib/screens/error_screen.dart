import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/auth_model.dart';
import '../providers/attendance_provider.dart';

class ErrorScreen extends StatefulWidget {
  const ErrorScreen({super.key});

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _contentController;
  late AnimationController _shakeController;

  late Animation<double> _iconScale;
  late Animation<double> _iconOpacity;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _runSequence();
  }

  void _initAnimations() {
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeIn,
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  Future<void> _runSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _iconController.forward();

    // Shake the icon once for emphasis
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await _shakeController.forward(from: 0);

    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await _contentController.forward();
  }

  @override
  void dispose() {
    _iconController.dispose();
    _contentController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _goHome() {
    context.read<AttendanceProvider>().resetValidation();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppConstants.routeHome,
      (route) => false,
    );
  }

  void _tryScanAgain() {
    context.read<AttendanceProvider>().resetValidation();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppConstants.routeScanner,
      (route) => route.settings.name == AppConstants.routeHome,
    );
  }

  void _retryValidation() {
    context.read<AttendanceProvider>().clearScannedToken();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppConstants.routeScanner,
      (route) => route.settings.name == AppConstants.routeHome,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final errorType = provider.errorType ?? AttendanceErrorType.unknown;
    final errorTitle = provider.errorTitle ?? 'Error Occurred';
    final errorMessage =
        provider.errorMessage ?? 'An unexpected error occurred. Please try again.';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final config = _ErrorConfig.fromType(errorType);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    Color.lerp(AppTheme.darkBackground,
                        config.color.withOpacity(0.3), 0.15)!,
                    AppTheme.darkBackground,
                  ]
                : [
                    config.color.withOpacity(0.06),
                    const Color(0xFFFFFBFB),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),

                  // ── Animated error icon ──────────────────────────────
                  _buildErrorIcon(config),

                  const SizedBox(height: 28),

                  // ── Title & message ──────────────────────────────────
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: _buildTitleSection(
                        errorTitle,
                        errorMessage,
                        config,
                        isDark,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Detail card ──────────────────────────────────────
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: _buildDetailCard(errorType, config, isDark),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Actions ──────────────────────────────────────────
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: _buildActions(errorType, config),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Error icon ───────────────────────────────────────────────────────────

  Widget _buildErrorIcon(_ErrorConfig config) {
    return AnimatedBuilder(
      animation: Listenable.merge([_iconController, _shakeController]),
      builder: (context, _) {
        final shakeOffset = _shakeController.isAnimating
            ? _shakeAnim.value *
                (1.0 - _shakeController.value) *
                (1.0 - _shakeController.value)
            : 0.0;

        return FadeTransition(
          opacity: _iconOpacity,
          child: ScaleTransition(
            scale: _iconScale,
            child: Center(
              child: Transform.translate(
                offset: Offset(shakeOffset, 0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: config.color.withOpacity(0.06),
                      ),
                    ),
                    // Middle ring
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: config.color.withOpacity(0.12),
                      ),
                    ),
                    // Inner circle
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            config.color,
                            Color.lerp(config.color, Colors.black, 0.25)!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: config.color.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        config.icon,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Title section ────────────────────────────────────────────────────────

  Widget _buildTitleSection(
    String title,
    String message,
    _ErrorConfig config,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: config.color,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.55,
              ),
        ),
      ],
    );
  }

  // ─── Detail card ─────────────────────────────────────────────────────────

  Widget _buildDetailCard(
    AttendanceErrorType errorType,
    _ErrorConfig config,
    bool isDark,
  ) {
    final tips = _getTipsForError(errorType);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: config.color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: config.color.withOpacity(isDark ? 0.08 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: config.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: config.color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'What to do next',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: config.color,
                      ),
                ),
              ],
            ),
          ),

          // Tips list
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: tips.asMap().entries.map((entry) {
                final idx = entry.key;
                final tip = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: idx < tips.length - 1 ? 14 : 0,
                  ),
                  child: _TipRow(
                    number: idx + 1,
                    text: tip,
                    color: config.color,
                  ),
                );
              }).toList(),
            ),
          ),

          // Error type badge
          Padding(
            padding: const EdgeInsets.only(
                left: 20, right: 20, bottom: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: config.color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: config.color.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 14, color: config.color.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Text(
                    'Error code: ${_errorCodeString(errorType)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: config.color.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Widget _buildActions(AttendanceErrorType errorType, _ErrorConfig config) {
    final showRescan = errorType != AttendanceErrorType.alreadyValidated &&
        errorType != AttendanceErrorType.sessionClosed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary action depends on error type
        if (errorType == AttendanceErrorType.alreadyValidated)
          ElevatedButton.icon(
            onPressed: _goHome,
            icon: const Icon(Icons.home_rounded, size: 20),
            label: const Text('Back to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          )
        else if (errorType == AttendanceErrorType.sessionClosed)
          ElevatedButton.icon(
            onPressed: _goHome,
            icon: const Icon(Icons.home_rounded, size: 20),
            label: const Text('Back to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _retryValidation,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
            label: const Text('Scan QR Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: config.color,
              foregroundColor: Colors.white,
              shadowColor: config.color.withOpacity(0.4),
              elevation: 3,
            ),
          ),

        const SizedBox(height: 12),

        // Secondary: go home
        if (showRescan)
          OutlinedButton.icon(
            onPressed: _goHome,
            icon: const Icon(Icons.home_outlined, size: 20),
            label: const Text('Back to Home'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<String> _getTipsForError(AttendanceErrorType type) {
    switch (type) {
      case AttendanceErrorType.expired:
        return [
          'Ask your teacher to generate a new QR code for this session.',
          'QR codes are time-limited. Make sure to scan quickly.',
          'Check your device clock — it must be accurate.',
        ];
      case AttendanceErrorType.alreadyValidated:
        return [
          'Your attendance is already recorded. No action needed.',
          'Each student can only register once per session.',
          'Contact your teacher if you believe this is a mistake.',
        ];
      case AttendanceErrorType.invalidQr:
        return [
          'Make sure you are scanning the teacher\'s attendance QR code.',
          'Do not scan QR codes from other apps or websites.',
          'Ask your teacher to display the QR code clearly.',
        ];
      case AttendanceErrorType.sessionClosed:
        return [
          'The teacher has ended the attendance window for this session.',
          'Arrive on time for future sessions to register attendance.',
          'Contact your teacher if you were present but could not scan.',
        ];
      case AttendanceErrorType.studentNotFound:
        return [
          'Check that your Code Massar is entered correctly.',
          'Ensure you are enrolled in this course.',
          'Contact the administration if your account is missing.',
        ];
      case AttendanceErrorType.nameMismatch:
        return [
          'Verify your first and last name match the institution records.',
          'Check for spelling mistakes or extra spaces.',
          'Your name must match exactly as registered (not a nickname).',
        ];
      case AttendanceErrorType.noInternet:
        return [
          'Check your Wi-Fi or mobile data connection.',
          'Move to an area with better network coverage.',
          'Try disabling and re-enabling Wi-Fi or mobile data.',
        ];
      case AttendanceErrorType.timeout:
        return [
          'If you use Render, open your API URL in a browser first to wake the server, then scan again.',
          'Check mobile data or Wi‑Fi, then retry after 30–60 seconds.',
          'For local dev on PC: run Django with runserver 0.0.0.0:8000 and set DEV_HOST to your PC IP.',
        ];
      case AttendanceErrorType.unknown:
        return [
          'Try scanning the QR code again from the home screen.',
          'Ensure your app is up to date.',
          'If the problem persists, contact your teacher or IT support.',
        ];
    }
  }

  String _errorCodeString(AttendanceErrorType type) {
    switch (type) {
      case AttendanceErrorType.expired:
        return 'ERR_QR_EXPIRED';
      case AttendanceErrorType.alreadyValidated:
        return 'ERR_DUPLICATE_ATTENDANCE';
      case AttendanceErrorType.invalidQr:
        return 'ERR_INVALID_TOKEN';
      case AttendanceErrorType.sessionClosed:
        return 'ERR_SESSION_INACTIVE';
      case AttendanceErrorType.studentNotFound:
        return 'ERR_STUDENT_NOT_FOUND';
      case AttendanceErrorType.nameMismatch:
        return 'ERR_NAME_MISMATCH';
      case AttendanceErrorType.noInternet:
        return 'ERR_NO_INTERNET';
      case AttendanceErrorType.timeout:
        return 'ERR_TIMEOUT';
      case AttendanceErrorType.unknown:
        return 'ERR_UNKNOWN';
    }
  }
}

// ─── Error Configuration ──────────────────────────────────────────────────────

class _ErrorConfig {
  final Color color;
  final IconData icon;

  const _ErrorConfig({required this.color, required this.icon});

  factory _ErrorConfig.fromType(AttendanceErrorType type) {
    switch (type) {
      case AttendanceErrorType.expired:
        return const _ErrorConfig(
          color: Color(0xFFFBBC04),
          icon: Icons.timer_off_rounded,
        );
      case AttendanceErrorType.alreadyValidated:
        return _ErrorConfig(
          color: AppTheme.primary,
          icon: Icons.how_to_reg_rounded,
        );
      case AttendanceErrorType.invalidQr:
        return const _ErrorConfig(
          color: Color(0xFFEA4335),
          icon: Icons.qr_code_rounded,
        );
      case AttendanceErrorType.sessionClosed:
        return const _ErrorConfig(
          color: Color(0xFF9C27B0),
          icon: Icons.lock_clock_rounded,
        );
      case AttendanceErrorType.studentNotFound:
        return const _ErrorConfig(
          color: Color(0xFFEA4335),
          icon: Icons.person_off_rounded,
        );
      case AttendanceErrorType.nameMismatch:
        return const _ErrorConfig(
          color: Color(0xFFFF6D00),
          icon: Icons.person_search_rounded,
        );
      case AttendanceErrorType.noInternet:
        return const _ErrorConfig(
          color: Color(0xFF607D8B),
          icon: Icons.wifi_off_rounded,
        );
      case AttendanceErrorType.timeout:
        return const _ErrorConfig(
          color: Color(0xFF795548),
          icon: Icons.hourglass_disabled_rounded,
        );
      case AttendanceErrorType.unknown:
        return const _ErrorConfig(
          color: Color(0xFFEA4335),
          icon: Icons.error_outline_rounded,
        );
    }
  }
}

// ─── Tip Row Widget ───────────────────────────────────────────────────────────

class _TipRow extends StatelessWidget {
  final int number;
  final String text;
  final Color color;

  const _TipRow({
    required this.number,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark
                  ? AppTheme.darkTextPrimary.withOpacity(0.85)
                  : AppTheme.lightTextPrimary.withOpacity(0.75),
            ),
          ),
        ),
      ],
    );
  }
}
