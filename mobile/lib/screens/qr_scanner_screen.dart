import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../providers/attendance_provider.dart';
import '../utils/validators.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late AnimationController _animController;
  late Animation<double> _scanLineAnim;

  bool _isProcessing = false;
  bool _torchOn = false;
  bool _hasDetected = false;

  // Debounce timer to avoid multiple rapid triggers
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: [BarcodeFormat.qrCode],
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scannerController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── QR Detection handler ─────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _hasDetected) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    // Debounce: ignore rapid duplicate scans
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _processQrValue(rawValue.trim());
    });
  }

  Future<void> _processQrValue(String rawValue) async {
    if (_isProcessing || _hasDetected || !mounted) return;

    final token = _extractTokenFromQr(rawValue);

    // Accept either a raw UUID token or a validate URL containing ?token=
    if (token == null || !Validators.isValidQrToken(token)) {
      _showInvalidQrFeedback(rawValue);
      return;
    }

    setState(() {
      _isProcessing = true;
      _hasDetected = true;
    });

    // Haptic + visual feedback
    HapticFeedback.mediumImpact();

    // Pause the scanner
    await _scannerController.stop();

    if (!mounted) return;

    // Store token in provider
    context.read<AttendanceProvider>().setScannedToken(token);

    // Brief pause for UX
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    // Navigate to validation screen
    Navigator.of(context).pushReplacementNamed(
      AppConstants.routeValidation,
    );
  }

  String? _extractTokenFromQr(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) return null;

    if (Validators.isValidQrToken(value)) {
      return value;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    final tokenFromQuery = uri.queryParameters['token']?.trim();
    if (tokenFromQuery != null && tokenFromQuery.isNotEmpty) {
      return tokenFromQuery;
    }

    return null;
  }

  void _showInvalidQrFeedback(String rawValue) {
    HapticFeedback.lightImpact();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  AppStrings.invalidQr,
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.warningColor.withOpacity(0.95),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  Future<void> _toggleTorch() async {
    await _scannerController.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  Future<void> _flipCamera() async {
    await _scannerController.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ── Camera feed ────────────────────────────────────────────────
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return _CameraErrorWidget(
                  error: error.errorCode.name,
                  onRetry: () {
                    _scannerController.start();
                  },
                );
              },
            ),
          ),

          // ── Dark overlay with scanning window ──────────────────────────
          Positioned.fill(
            child: _ScanOverlay(size: size),
          ),

          // ── Animated scan line ─────────────────────────────────────────
          Positioned.fill(
            child: _AnimatedScanLine(animation: _scanLineAnim, size: size),
          ),

          // ── Status bar (top) ───────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopStatusBar(),
          ),

          // ── Bottom controls ────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),

          // ── Processing overlay ─────────────────────────────────────────
          if (_isProcessing)
            Positioned.fill(
              child: _ProcessingOverlay(),
            ),
        ],
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        AppStrings.scanQrCode,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        // Torch toggle
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _torchOn
                  ? AppTheme.warningColor.withOpacity(0.85)
                  : Colors.black45,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _torchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: _toggleTorch,
          tooltip: AppStrings.toggleFlash,
        ),
        // Flip camera
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flip_camera_ios_rounded,
                color: Colors.white, size: 20),
          ),
          onPressed: _flipCamera,
          tooltip: AppStrings.flipCamera,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Top status bar ───────────────────────────────────────────────────────

  Widget _buildTopStatusBar() {
    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top + 20,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
    );
  }

  // ─── Bottom controls ──────────────────────────────────────────────────────

  Widget _buildBottomControls() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 32,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Instruction text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppStrings.alignQr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text(AppStrings.cancel),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38, width: 1.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scan Overlay (dark mask + transparent frame) ─────────────────────────────

class _ScanOverlay extends StatelessWidget {
  final Size size;

  const _ScanOverlay({required this.size});

  @override
  Widget build(BuildContext context) {
    const frameSize = 260.0;
    const cornerRadius = 20.0;
    const cornerLength = 32.0;
    const cornerThickness = 4.0;

    return CustomPaint(
      painter: _ScanOverlayPainter(
        frameSize: frameSize,
        cornerRadius: cornerRadius,
        cornerLength: cornerLength,
        cornerThickness: cornerThickness,
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double frameSize;
  final double cornerRadius;
  final double cornerLength;
  final double cornerThickness;

  const _ScanOverlayPainter({
    required this.frameSize,
    required this.cornerRadius,
    required this.cornerLength,
    required this.cornerThickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 40; // slightly above center
    final left = cx - frameSize / 2;
    final top = cy - frameSize / 2;
    final right = cx + frameSize / 2;
    final bottom = cy + frameSize / 2;
    final frameRect = RRect.fromLTRBR(
      left, top, right, bottom,
      Radius.circular(cornerRadius),
    );

    // Dark overlay
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.65);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(frameRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    // Corner brackets
    final cornerPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerThickness
      ..strokeCap = StrokeCap.round;

    final r = cornerRadius;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + r + cornerLength)
        ..lineTo(left, top + r)
        ..arcToPoint(Offset(left + r, top),
            radius: Radius.circular(r), clockwise: true)
        ..lineTo(left + r + cornerLength, top),
      cornerPaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(right - r - cornerLength, top)
        ..lineTo(right - r, top)
        ..arcToPoint(Offset(right, top + r),
            radius: Radius.circular(r), clockwise: true)
        ..lineTo(right, top + r + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - r - cornerLength)
        ..lineTo(left, bottom - r)
        ..arcToPoint(Offset(left + r, bottom),
            radius: Radius.circular(r), clockwise: false)
        ..lineTo(left + r + cornerLength, bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(right - r - cornerLength, bottom)
        ..lineTo(right - r, bottom)
        ..arcToPoint(Offset(right, bottom - r),
            radius: Radius.circular(r), clockwise: false)
        ..lineTo(right, bottom - r - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Animated Scan Line ───────────────────────────────────────────────────────

class _AnimatedScanLine extends StatelessWidget {
  final Animation<double> animation;
  final Size size;

  const _AnimatedScanLine({required this.animation, required this.size});

  @override
  Widget build(BuildContext context) {
    const frameSize = 260.0;
    const cornerRadius = 20.0;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final cx = size.width / 2;
        final cy = size.height / 2 - 40;
        final top = cy - frameSize / 2;
        const padding = cornerRadius;
        final lineY =
            top + padding + (frameSize - padding * 2) * animation.value;

        return CustomPaint(
          painter: _ScanLinePainter(
            lineY: lineY,
            cx: cx,
            halfWidth: frameSize / 2 - 16,
          ),
        );
      },
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double lineY;
  final double cx;
  final double halfWidth;

  const _ScanLinePainter({
    required this.lineY,
    required this.cx,
    required this.halfWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppTheme.primary.withOpacity(0.9),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(cx - halfWidth, lineY - 1, halfWidth * 2, 2),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawLine(
      Offset(cx - halfWidth, lineY),
      Offset(cx + halfWidth, lineY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter old) =>
      old.lineY != lineY;
}

// ─── Processing Overlay ───────────────────────────────────────────────────────

class _ProcessingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              AppStrings.processingQr,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Camera Error Widget ──────────────────────────────────────────────────────

class _CameraErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _CameraErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined,
                  color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              const Text(
                AppStrings.cameraUnavailable,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.cameraPermission,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $error',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(AppStrings.retry),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
