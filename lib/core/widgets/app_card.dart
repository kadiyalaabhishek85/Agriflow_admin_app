import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderRadius = AppColors.radiusMd,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration = BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppColors.line,
        width: 1.0,
      ),
      boxShadow: boxShadow,
    );

    Widget content;
    if (onTap != null) {
      // `Ink` (not `Container`) so the card surface and the InkWell ripple
      // share the same Material canvas and the ripple stays visible.
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.surfaceAlt,
          child: Ink(
            padding: padding,
            decoration: decoration,
            child: child,
          ),
        ),
      );
    } else {
      content = Container(
        padding: padding,
        decoration: decoration,
        child: child,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }
    return content;
  }
}

class StatCard extends StatelessWidget {
  final Widget icon;
  final Color iconBackgroundColor;
  final String value;
  final String label;
  final String? deltaText;
  final Color? deltaColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconBackgroundColor,
    required this.value,
    required this.label,
    this.deltaText,
    this.deltaColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.displayMedium(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall(color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (deltaText != null) ...[
            const SizedBox(height: 4),
            Text(
              deltaText!,
              style: AppTypography.monoSmall(
                color: deltaColor ?? AppColors.good,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
