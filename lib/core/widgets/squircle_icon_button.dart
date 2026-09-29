import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Minimum touch-target dimension required by WCAG 2.5.5 / Material
/// accessibility guidelines (ISSUE-P3-03, pre-m8-stabilization-audit.md §16).
const double kMinTouchTargetSize = 48.0;

class SquircleIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final bool hasBadge;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final String? tooltip;

  const SquircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.hasBadge = false,
    this.backgroundColor,
    this.borderColor,
    this.size = 38.0,
    this.tooltip,
  });

  factory SquircleIconButton.back({
    Key? key,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return SquircleIconButton(
      key: key,
      size: 38.0,
      onTap: onTap,
      icon: Icon(
        Icons.chevron_left_rounded,
        size: 20,
        color: iconColor ?? AppColors.forest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The painted button keeps its requested [size]; the hit container is
    // expanded to at least 48x48dp so small variants (32/36/38) remain
    // comfortably tappable without any layout change to the visual box.
    final double hitSize =
        size < kMinTouchTargetSize ? kMinTouchTargetSize : size;

    Widget visual = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: borderColor ?? AppColors.line,
                width: 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          if (hasBadge)
            Positioned(
              top: 7,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.alert,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );

    Widget button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      splashColor: AppColors.surfaceAlt,
      highlightColor: AppColors.surfaceAlt.withValues(alpha: 0.5),
      child: SizedBox(
        width: hitSize,
        height: hitSize,
        child: Center(child: visual),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
