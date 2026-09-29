import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography definitions matching the approved HTML UI:
/// - Primary: Manrope
/// - Display / Headers: Fraunces
/// - Code / Money / Data: JetBrains Mono
abstract class AppTypography {
  // Fraunces (Display / Serifs)
  static TextStyle displayLarge({Color color = AppColors.text, FontWeight fontWeight = FontWeight.w600}) {
    return GoogleFonts.fraunces(
      fontSize: 26,
      fontWeight: fontWeight,
      color: color,
      height: 1.25,
    );
  }

  static TextStyle displayMedium({Color color = AppColors.text, FontWeight fontWeight = FontWeight.w600}) {
    return GoogleFonts.fraunces(
      fontSize: 21,
      fontWeight: fontWeight,
      color: color,
      height: 1.25,
    );
  }

  static TextStyle displaySmall({Color color = AppColors.text, FontWeight fontWeight = FontWeight.w600}) {
    return GoogleFonts.fraunces(
      fontSize: 18,
      fontWeight: fontWeight,
      color: color,
      height: 1.25,
    );
  }

  // Manrope (Primary Sans-Serif Body & Titles)
  static TextStyle titleLarge({Color color = AppColors.text, FontWeight fontWeight = FontWeight.w800}) {
    return GoogleFonts.manrope(
      fontSize: 18,
      fontWeight: fontWeight,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle titleMedium({Color color = AppColors.text, FontWeight fontWeight = FontWeight.w800}) {
    return GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: fontWeight,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle titleSmall({Color color = AppColors.text, FontWeight fontWeight = FontWeight.w700}) {
    return GoogleFonts.manrope(
      fontSize: 13.5,
      fontWeight: fontWeight,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle bodyMedium({Color color = AppColors.text, FontWeight fontWeight = FontWeight.w600}) {
    return GoogleFonts.manrope(
      fontSize: 13.5,
      fontWeight: fontWeight,
      color: color,
      height: 1.45,
    );
  }

  static TextStyle bodySmall({Color color = AppColors.textMuted, FontWeight fontWeight = FontWeight.w600}) {
    return GoogleFonts.manrope(
      fontSize: 12,
      fontWeight: fontWeight,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle caption({Color color = AppColors.textMuted, FontWeight fontWeight = FontWeight.w600}) {
    return GoogleFonts.manrope(
      fontSize: 11,
      fontWeight: fontWeight,
      color: color,
      height: 1.35,
    );
  }

  static TextStyle eyebrow({Color color = AppColors.adminNavy}) {
    return GoogleFonts.manrope(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.09 * 11,
      color: color,
    );
  }

  static TextStyle button({Color color = Colors.white, FontWeight fontWeight = FontWeight.w800}) {
    return GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // JetBrains Mono (Financial amounts, IDs, dates, numbers)
  static TextStyle monoLarge({Color color = AppColors.text, FontWeight fontWeight = FontWeight.w800}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 20,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: -0.5,
    );
  }

  static TextStyle monoMedium({Color color = AppColors.text, FontWeight fontWeight = FontWeight.w700}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 14,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle monoSmall({Color color = AppColors.textFaint, FontWeight fontWeight = FontWeight.w600}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 11.5,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
