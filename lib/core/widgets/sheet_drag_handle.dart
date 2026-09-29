import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Shared bottom-sheet drag handle (flutter-03 rec 11: replaces the
/// copy-pasted `Center > Container(width: 40, height: 4, ...)` block that
/// appeared in every sheet).
class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key, this.margin});

  /// Optional spacing that sheets previously attached via a container
  /// margin (e.g. `EdgeInsets.only(bottom: 16)`).
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: margin,
        decoration: BoxDecoration(
          color: AppColors.line,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
