import 'package:flutter/material.dart';

/// Design tokens extracted directly from the approved Admin/Manager HTML UI.
/// CSS variables:
/// --bg: #F3F6EC
/// --surface: #FFFFFF
/// --surface-alt: #E9F0DD
/// --forest: #15302A
/// --forest-soft: #1F4438
/// --canopy: #2E7D5B
/// --canopy-deep: #1F5C42
/// --canopy-light: #7BC79A
/// --amber: #E39A3B
/// --amber-soft: #F6E2BE
/// --clay: #B4794C
/// --clay-soft: #F1E1D0
/// --text: #1C2A21
/// --text-muted: #657268
/// --text-faint: #8B9689
/// --line: #E1E8D8
/// --alert: #D9704C
/// --admin-navy: #1E3A5C
/// --admin-navy-deep: #16293F
/// --admin-navy-light: #4C7BAA
abstract class AppColors {
  // Primary Backgrounds & Surfaces
  static const Color background = Color(0xFFF3F6EC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFE9F0DD);

  // Forest & Canopy Greens (Agri theme)
  static const Color forest = Color(0xFF15302A);
  static const Color forestSoft = Color(0xFF1F4438);
  static const Color canopy = Color(0xFF2E7D5B);
  static const Color canopyDeep = Color(0xFF1F5C42);
  static const Color canopyLight = Color(0xFF7BC79A);

  // Earth / Warm Accent tones
  static const Color amber = Color(0xFFE39A3B);
  static const Color amberSoft = Color(0xFFF6E2BE);
  static const Color clay = Color(0xFFB4794C);
  static const Color claySoft = Color(0xFFF1E1D0);

  // Typography & Content
  // --text-muted / --text-faint are darkened from the HTML tokens
  // (#657268 / #8B9689, 4.62:1 / 2.82:1 on --bg) to meet WCAG AA 4.5:1
  // on background (#F3F6EC), surface (#FFFFFF) and surface-alt (#E9F0DD).
  // ISSUE-P3-01, pre-m8-stabilization-audit.md §16.
  static const Color text = Color(0xFF1C2A21);
  static const Color textMuted = Color(0xFF4E5A51); // 6.6:1 on --bg
  static const Color textFaint = Color(0xFF5F6C63); // 5.0:1 on --bg
  static const Color line = Color(0xFFE1E8D8);

  // Status & Feedback
  static const Color alert = Color(0xFFD9704C);
  static const Color good = Color(0xFF28653F);
  static const Color goodBg = Color(0xFFDFF0DF);
  static const Color goodLight = goodBg;
  static const Color warn = Color(0xFF8A5C15);
  static const Color warnBg = Color(0xFFF6E2BE);
  static const Color warnLight = warnBg;
  static const Color bad = Color(0xFFA6431E);
  static const Color badBg = Color(0xFFF7DDD2);
  static const Color badLight = badBg;
  static const Color primaryLight = canopyLight;

  // Navy theme (Admin / Manager brand)
  static const Color adminNavy = Color(0xFF1E3A5C);
  static const Color adminNavyDeep = Color(0xFF16293F);
  static const Color adminNavyLight = Color(0xFF4C7BAA);
  static const Color infoBg = Color(0xFFE1EBF6);

  // Radii
  static const double radiusSm = 12.0;
  static const double radiusMd = 18.0;
  static const double radiusLg = 26.0;

  // Box Shadows
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color.fromRGBO(21, 48, 42, 0.12),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color.fromRGBO(21, 48, 42, 0.16),
      blurRadius: 26,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromRGBO(21, 48, 42, 0.08),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}
