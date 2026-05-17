import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../services/connectivity_service.dart';

/// A slim animated banner that slides down from the top of the screen
/// whenever the device loses internet connectivity, and slides back up
/// when the connection is restored.
///
/// Wrap your scaffold body (or place it inside a [Column] above the main
/// content) to show it contextually:
///
/// ```dart
/// Column(
///   children: [
///     const ConnectivityBanner(),
///     Expanded(child: myContent),
///   ],
/// )
/// ```
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late final ConnectivityService _connectivityService;
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  StreamSubscription<bool>? _subscription;

  bool _isOffline = false;

  @override
  void initState() {
    super.initState();

    _connectivityService = ConnectivityService();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    // Check current state immediately
    final connected = await _connectivityService.isConnected();
    if (!mounted) return;

    if (!connected) {
      _showBanner();
    }

    // Listen for future changes
    _subscription =
        _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (!mounted) return;
      if (!isConnected && !_isOffline) {
        _showBanner();
      } else if (isConnected && _isOffline) {
        _hideBanner();
      }
    });
  }

  void _showBanner() {
    setState(() => _isOffline = true);
    _animController.forward();
  }

  void _hideBanner() {
    _animController.reverse().then((_) {
      if (mounted) setState(() => _isOffline = false);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline && !_animController.isAnimating) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: _BannerContent(
          onDismiss: _hideBanner,
        ),
      ),
    );
  }
}

// ─── Banner Content ───────────────────────────────────────────────────────────

class _BannerContent extends StatelessWidget {
  final VoidCallback onDismiss;

  const _BannerContent({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      elevation: 4,
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF37474F)
              : const Color(0xFF455A64),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              // ── Pulsing wifi-off icon ────────────────────────────────
              const _PulsingIcon(),

              const SizedBox(width: 12),

              // ── Message ───────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No Internet Connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Some features may be unavailable.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── Dismiss button ────────────────────────────────────────
              GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withOpacity(0.7),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pulsing Wifi-Off Icon ────────────────────────────────────────────────────

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon();

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnim.value,
          child: child,
        );
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.wifi_off_rounded,
          color: Colors.white,
          size: 17,
        ),
      ),
    );
  }
}

// ─── Overlay variant ──────────────────────────────────────────────────────────

/// An alternative approach: wrap any widget to automatically show the banner
/// as an overlay at the top.
///
/// ```dart
/// ConnectivityWrapper(
///   child: Scaffold(...),
/// )
/// ```
class ConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ConnectivityBanner(),
        Expanded(child: child),
      ],
    );
  }
}
