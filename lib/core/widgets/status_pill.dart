import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

enum PillType {
  good,
  warn,
  bad,
  info,
  neutral;

  Color get backgroundColor {
    switch (this) {
      case PillType.good:
        return AppColors.goodBg;
      case PillType.warn:
        return AppColors.warnBg;
      case PillType.bad:
        return AppColors.badBg;
      case PillType.info:
        return AppColors.infoBg;
      case PillType.neutral:
        return AppColors.surfaceAlt;
    }
  }

  Color get textColor {
    switch (this) {
      case PillType.good:
        return AppColors.good;
      case PillType.warn:
        return AppColors.warn;
      case PillType.bad:
        return AppColors.bad;
      case PillType.info:
        return AppColors.adminNavyDeep;
      case PillType.neutral:
        return AppColors.canopyDeep;
    }
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final PillType type;
  final Widget? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.type,
    this.icon,
  });

  /// Factory constructor that automatically detects the status string and maps to
  /// the exact styling prescribed in the approved HTML reference.
  factory StatusPill.fromStatus(String? status, {String? customLabel}) {
    final s = (status ?? '').toLowerCase().trim();
    PillType resolvedType = PillType.neutral;
    String display = customLabel ?? (s.isEmpty ? 'Unknown' : s[0].toUpperCase() + s.substring(1));
    if (customLabel == null) {
      display = display.replaceAll('_', ' ');
    }

    switch (s) {
      case 'approved':
      case 'delivered':
      case 'paid':
      case 'active':
      case 'completed':
      case 'good':
      case 'open':
        resolvedType = PillType.good;
        break;
      case 'pending':
      case 'pending_review':
      case 'in_progress':
      case 'inprogress':
      case 'warn':
      case 'received':
        resolvedType = PillType.warn;
        break;
      case 'rejected':
      case 'cancelled':
      case 'failed':
      case 'overdue':
      case 'full':
      case 'bad':
        resolvedType = PillType.bad;
        break;
      case 'upcoming':
      case 'scheduled':
      case 'confirmed':
      case 'inspected':
      case 'info':
        resolvedType = PillType.info;
        break;
      default:
        resolvedType = PillType.neutral;
        break;
    }

    return StatusPill(
      label: display,
      type: resolvedType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: type.backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: type.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
