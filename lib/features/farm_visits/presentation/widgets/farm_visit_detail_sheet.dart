import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/farm_visit_item.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

class FarmVisitDetailSheet extends StatelessWidget {
  final FarmVisitItem item;
  final VoidCallback onReschedule;
  final VoidCallback onComplete;

  const FarmVisitDetailSheet({
    super.key,
    required this.item,
    required this.onReschedule,
    required this.onComplete,
  });

  static Future<void> show(
    BuildContext context, {
    required FarmVisitItem item,
    required VoidCallback onReschedule,
    required VoidCallback onComplete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FarmVisitDetailSheet(
        item: item,
        onReschedule: onReschedule,
        onComplete: onComplete,
      ),
    );
  }

  String _formatDate(String? dateStr) {
    return AppDates.dayMonthYear(dateStr, fallback: 'Not set');
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = item.isEditable;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            SheetDragHandle(),
            const SizedBox(height: 16),

            // Header Row: Status + Visit ID + Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    StatusPill.fromStatus(item.status),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'Month ${item.visitMonth}',
                        style: AppTypography.caption(color: AppColors.textMuted).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Farmer Info Section
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.canopy.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.farmerInitials,
                    style: AppTypography.titleLarge(color: AppColors.canopyDeep).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayFarmerName,
                        style: AppTypography.titleLarge(color: AppColors.text).copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (item.enrichedFarmerPhone != null && item.enrichedFarmerPhone!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              item.enrichedFarmerPhone!,
                              style: AppTypography.bodySmall(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            item.displayVillage,
                            style: AppTypography.bodySmall(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Crop Details Card matching HTML
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                border: Border.all(color: const Color(0xFFCDEBD6)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Crop',
                        style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item.displayCropName,
                        style: AppTypography.bodyMedium(color: AppColors.text).copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (item.enrichedCropAcres != null && item.enrichedCropAcres!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Acres',
                          style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${item.enrichedCropAcres} acres',
                          style: AppTypography.bodyMedium(color: AppColors.text).copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Schedule Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FC),
                border: Border.all(color: const Color(0xFFD3E3F7)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scheduled Date',
                        style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _formatDate(item.scheduledDate),
                        style: AppTypography.bodyMedium(color: AppColors.adminNavy).copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Field Officer',
                        style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item.displayStaffName,
                        style: AppTypography.bodyMedium(color: AppColors.text).copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (item.actualDate != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Actual Date',
                          style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _formatDate(item.actualDate),
                          style: AppTypography.bodyMedium(color: AppColors.good).copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Report / Observations / Field Photo if completed
            _buildReportAndPhotoSection(context),

            // Action Buttons
            if (isEditable) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReschedule,
                      icon: const Icon(Icons.edit_calendar, size: 16),
                      label: const Text('Reschedule'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AppColors.canopy,
                        side: const BorderSide(color: AppColors.canopy),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.good,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Center(
                child: Text(
                  item.isCompleted
                      ? 'This visit has been marked as complete.'
                      : 'This visit is ${item.status}.',
                  style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportAndPhotoSection(BuildContext context) {
    final cleanNotes = item.cleanReportNotes;
    final photoUrl = item.fieldPhotoUrl;

    if (cleanNotes == null && photoUrl == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cleanNotes != null && cleanNotes.isNotEmpty) ...[
          Text(
            'Visit Report',
            style: AppTypography.titleSmall(color: AppColors.text).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              cleanNotes,
              style: AppTypography.bodyMedium(color: AppColors.text),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (photoUrl != null && photoUrl.isNotEmpty) ...[
          Text(
            'Field Photo',
            style: AppTypography.titleSmall(color: AppColors.text).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            key: const Key('farm_visit_detail_field_photo'),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openFullScreenImage(context, photoUrl),
                  child: Image.network(
                    photoUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 160,
                        color: AppColors.surfaceAlt,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.canopy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Loading field photo...',
                              style: AppTypography.caption(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: AppColors.surfaceAlt,
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.broken_image_outlined,
                              size: 32,
                              color: AppColors.textFaint,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Field photo unavailable',
                              style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  void _openFullScreenImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Photo unavailable',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(dialogCtx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
