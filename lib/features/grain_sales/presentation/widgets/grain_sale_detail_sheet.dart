import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/detail_row.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/grain_sale_item.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Modal bottom sheet displaying complete grain sale transaction details.
class GrainSaleDetailSheet extends StatefulWidget {
  final GrainSaleItem item;
  final bool isSubmitting;
  final FutureOr<void> Function()? onPay;
  final FutureOr<void> Function()? onReview;
  final FutureOr<void> Function()? onReject;
  final FutureOr<void> Function()? onUpdateYield;
  final String? Function()? errorMessage;

  const GrainSaleDetailSheet({
    super.key,
    required this.item,
    required this.isSubmitting,
    this.onPay,
    this.onReview,
    this.onReject,
    this.onUpdateYield,
    this.errorMessage,
  });

  static Future<void> show({
    required BuildContext context,
    required GrainSaleItem item,
    required bool isSubmitting,
    FutureOr<void> Function()? onPay,
    FutureOr<void> Function()? onReview,
    FutureOr<void> Function()? onReject,
    FutureOr<void> Function()? onUpdateYield,
    String? Function()? errorMessage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GrainSaleDetailSheet(
        item: item,
        isSubmitting: isSubmitting,
        onPay: onPay,
        onReview: onReview,
        onReject: onReject,
        onUpdateYield: onUpdateYield,
        errorMessage: errorMessage,
      ),
    );
  }

  @override
  State<GrainSaleDetailSheet> createState() => _GrainSaleDetailSheetState();
}

class _GrainSaleDetailSheetState extends State<GrainSaleDetailSheet> {
  bool _busy = false;
  String? _actionError;

  Future<void> _runAction(FutureOr<void> Function()? action) async {
    if (action == null || _busy || widget.isSubmitting) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _actionError = widget.errorMessage?.call();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final busy = _busy || widget.isSubmitting;
    final shortId = item.id.length > 8 ? item.id.substring(0, 8) : item.id;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            SheetDragHandle(),
            const SizedBox(height: 16),

            // Header row with ID and Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GRAIN SALE #$shortId',
                        style: AppTypography.eyebrow(color: AppColors.canopyDeep),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Procurement Details',
                        style: AppTypography.titleLarge(color: AppColors.text),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Farmer Profile Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.canopyLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.canopy.withValues(alpha: 0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.farmerInitials,
                      style: AppTypography.titleMedium(color: AppColors.canopyDeep),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayFarmerName,
                          style: AppTypography.titleSmall(color: AppColors.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.enrichedFarmerPhone != null && item.enrichedFarmerPhone!.isNotEmpty
                              ? '${item.enrichedFarmerPhone} · ${item.displayVillage}'
                              : item.displayVillage,
                          style: AppTypography.bodySmall(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  StatusPill.fromStatus(item.status),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Procurement Quantities & Grading Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  DetailRow('Crop Type', item.grainType),
                  DetailRow('Assigned Grade', 'Grade ${item.grade}'),
                  const Divider(color: AppColors.line, height: 16),
                  DetailRow(
                    'Raw Intake',
                    '${item.rawMaterialQuintals} qtl (${item.rawMaterialKg} kg)',
                  ),
                  DetailRow(
                    'Good Material',
                    '${item.goodMaterialQuintals} qtl (${item.goodMaterialKg} kg)',
                    valueColor: AppColors.good,
                  ),
                  DetailRow(
                    'Wastage / Moisture',
                    '${item.wastageQuintals} qtl (${item.wastageKg} kg)',
                    valueColor: AppColors.alert,
                  ),
                  const Divider(color: AppColors.line, height: 16),
                  DetailRow('Procurement Rate', item.displayRate),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Total Payout Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Payout Amount',
                    style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.displayTotalPayout,
                    style: AppTypography.monoLarge(color: AppColors.text),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_actionError != null) ...[
              Container(
                key: const Key('grain_sale_detail_error'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.alert.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.alert.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _actionError!,
                  style: AppTypography.bodySmall(color: AppColors.alert),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Actions Section
            if (item.isPaid) ...[
              Container(
                key: const Key('grain_sale_paid_banner'),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.good.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.good.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.good, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'This transaction has been paid.',
                      style: AppTypography.bodySmall(color: AppColors.good).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (item.isRejected) ...[
              Container(
                key: const Key('grain_sale_rejected_banner'),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.alert.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.alert.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cancel_outlined, color: AppColors.alert, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'This procurement was rejected.',
                      style: AppTypography.bodySmall(color: AppColors.alert).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (item.isApproved) ...[
              ElevatedButton(
                key: const Key('grain_sale_mark_as_paid_btn'),
                onPressed: (busy || widget.onPay == null) ? null : () => _runAction(widget.onPay),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.canopyDeep,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.canopyDeep.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Mark as Paid',
                            style: AppTypography.titleSmall(color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ] else if (item.isReceived || item.status.toLowerCase() == 'pending') ...[
              Row(
                children: [
                  if (widget.onReject != null) ...[
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        key: const Key('grain_sale_reject_btn'),
                        onPressed: busy ? null : () => _runAction(widget.onReject),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.alert,
                          side: const BorderSide(color: AppColors.alert),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Reject',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      key: const Key('grain_sale_review_approve_btn'),
                      onPressed: (busy || widget.onReview == null)
                          ? null
                          : () => _runAction(widget.onReview),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.canopyDeep,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.canopyDeep.withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.fact_check_outlined, size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Review & Approve',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.titleSmall(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],

            // Yield correction — allowed while the sale is still open
            // (not paid, not rejected); backend enforces final state rules.
            if (widget.onUpdateYield != null && !item.isPaid && !item.isRejected) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('grain_sale_update_yield_btn'),
                onPressed: busy ? null : () => _runAction(widget.onUpdateYield),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.canopyDeep,
                  side: const BorderSide(color: AppColors.canopyDeep),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.scale_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Update Yield',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
