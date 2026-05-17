import 'package:flutter/material.dart';

import '../constants/app_theme.dart';

/// A reusable app logo widget that renders the AttendQR brand mark.
///
/// Usage:
/// ```dart
/// AppLogo(size: 80)
/// AppLogo(size: 120, showShadow: false)
/// ```
class AppLogo extends StatelessWidget {
  /// The overall bounding size (width = height = [size]).
  final double size;

  /// Whether to draw a drop shadow beneath the logo container.
  final bool showShadow;

  /// Optional background color override. Defaults to white.
  final Color? backgroundColor;

  /// Corner radius of the logo container. Defaults to [size] * 0.25.
  final double? borderRadius;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showShadow = true,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final double r = borderRadius ?? size * 0.25;
    final double innerSize = size * 0.55;
    final double iconSize = innerSize * 0.6;
    final double bgIconSize = size * 0.65;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(r),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.18),
                  blurRadius: size * 0.4,
                  spreadRadius: 0,
                  offset: Offset(0, size * 0.1),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: size * 0.18,
                  spreadRadius: 0,
                  offset: Offset(0, size * 0.04),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Decorative QR background icon ─────────────────────────
            Icon(
              Icons.qr_code_2_rounded,
              size: bgIconSize,
              color: AppTheme.primary.withOpacity(0.10),
            ),

            // ── Foreground gradient badge ──────────────────────────────
            Container(
              width: innerSize,
              height: innerSize,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary,
                    AppTheme.primaryDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(innerSize * 0.28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.35),
                    blurRadius: innerSize * 0.5,
                    offset: Offset(0, innerSize * 0.15),
                  ),
                ],
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: iconSize,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact inline logo + text combination for use in app bars or headers.
class AppLogoInline extends StatelessWidget {
  final double logoSize;
  final double fontSize;
  final Color? textColor;

  const AppLogoInline({
    super.key,
    this.logoSize = 32,
    this.fontSize = 18,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedTextColor = textColor ??
        (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(
          size: logoSize,
          showShadow: false,
          backgroundColor: Colors.transparent,
          borderRadius: logoSize * 0.25,
        ),
        const SizedBox(width: 8),
        Text(
          'AttendQR',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: resolvedTextColor,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
