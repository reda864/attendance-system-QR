import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../providers/attendance_provider.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _contentController;
  late AnimationController _pulseController;

  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _runSequence();
  }

  void _initAnimations() {
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );

    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _runSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _checkController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _contentController.forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _goHome() {
    context.read<AttendanceProvider>().resetValidation();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppConstants.routeHome,
      (route) => false,
    );
  }

  void _scanAnother() {
    context.read<AttendanceProvider>().resetValidation();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppConstants.routeScanner,
      (route) => route.settings.name == AppConstants.routeHome,
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload =
        context.watch<AttendanceProvider>().successPayload;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0A2010),
                    AppTheme.darkBackground,
                  ]
                : [
                    const Color(0xFFEAF7EE),
                    const Color(0xFFF8FFF9),
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

                  // ── Animated check icon ──────────────────────────────
                  _buildCheckIcon(),

                  const SizedBox(height: 28),

                  // ── Title + subtitle ─────────────────────────────────
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: _buildTitleSection(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Details card ─────────────────────────────────────
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: _buildDetailsCard(payload, isDark),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Actions ──────────────────────────────────────────
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: _buildActions(),
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

  // ─── Check icon ───────────────────────────────────────────────────────────

  Widget _buildCheckIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([_checkController, _pulseController]),
      builder: (context, _) {
        return FadeTransition(
          opacity: _checkOpacity,
          child: ScaleTransition(
            scale: _checkScale,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulse ring
                  Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.successColor.withOpacity(0.08),
                      ),
                    ),
                  ),
                  // Middle ring
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.successColor.withOpacity(0.14),
                    ),
                  ),
                  // Inner circle with icon
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF34A853),
                          Color(0xFF1E8C3A),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x5534A853),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Title section ────────────────────────────────────────────────────────

  Widget _buildTitleSection() {
    return Column(
      children: [
        Text(
          'Attendance Registered!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.successColor,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Your attendance has been successfully\nrecorded for this session.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  // ─── Details card ─────────────────────────────────────────────────────────

  Widget _buildDetailsCard(dynamic payload, bool isDark) {
    final validationTime = payload?.formattedValidationTime ?? '—';
    final sessionId = payload?.session?.toString() ?? '—';
    final attendanceId = payload?.id?.toString() ?? '—';

    // Parse date and time from formattedValidationTime
    String dateStr = '—';
    String timeStr = '—';
    if (payload != null) {
      final dt = payload.validationDateTime as DateTime?;
      if (dt != null) {
        String pad(int n) => n.toString().padLeft(2, '0');
        dateStr =
            '${dt.year}-${pad(dt.month)}-${pad(dt.day)}';
        timeStr =
            '${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.successColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withOpacity(isDark ? 0.1 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.08),
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
                    color: AppTheme.successColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.successColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Attendance Receipt',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'CONFIRMED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.successColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details rows
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.tag_rounded,
                  label: 'Attendance ID',
                  value: '#$attendanceId',
                  valueColor: AppTheme.primary,
                ),
                const SizedBox(height: 14),
                _DetailRow(
                  icon: Icons.class_outlined,
                  label: 'Session',
                  value: 'Session #$sessionId',
                ),
                const SizedBox(height: 14),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: dateStr,
                ),
                const SizedBox(height: 14),
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Validated at',
                  value: timeStr,
                  valueColor: AppTheme.successColor,
                ),
                const SizedBox(height: 16),

                // Status banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.successColor.withOpacity(0.2),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: AppTheme.successColor,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Present — Attendance recorded successfully',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary: Go home
        ElevatedButton.icon(
          onPressed: _goHome,
          icon: const Icon(Icons.home_rounded, size: 20),
          label: const Text('Back to Home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            foregroundColor: Colors.white,
            shadowColor: AppTheme.successColor.withOpacity(0.4),
            elevation: 3,
          ),
        ),

        const SizedBox(height: 12),

        // Secondary: Scan another
        OutlinedButton.icon(
          onPressed: _scanAnother,
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
          label: const Text('Scan Another QR'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
        ),
      ],
    );
  }
}

// ─── Detail Row Widget ────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: (isDark
                    ? AppTheme.darkSurface
                    : AppTheme.lightBackground),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 17,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ??
                      (isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
