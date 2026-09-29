import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

/// Edit affordance retained from the approved HTML `rate-editor` workflow.
///
/// There is no `PATCH/PUT /api/v1/market-rates/{id}` in the verified FastAPI
/// contract, so this action is visibly disabled and only reveals the
/// backend-required notice. It never modifies local state and never issues
/// a network call.
class EditRateDisabledAction extends StatelessWidget {
  final String cropName;

  const EditRateDisabledAction({
    super.key,
    required this.cropName,
  });

  static const String backendRequiredMessage =
      'Backend API required — to be supplied by Syed.';

  void _showNotice(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_clock_rounded, color: AppColors.warn, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Edit Market Rate',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          backendRequiredMessage,
          style: GoogleFonts.manrope(fontSize: 13.5, color: AppColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: AppColors.canopy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('market-rate-edit-disabled'),
      icon: const Icon(
        Icons.edit_outlined,
        size: 17,
        color: AppColors.textFaint,
      ),
      tooltip: 'Edit rate — backend pending',
      splashRadius: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: () => _showNotice(context),
    );
  }
}
