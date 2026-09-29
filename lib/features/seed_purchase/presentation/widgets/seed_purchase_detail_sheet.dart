import 'package:flutter/material.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/constants/app_typography.dart';
import 'package:agriflow_admin/core/utils/app_dates.dart';
import 'package:agriflow_admin/core/widgets/app_toast.dart';
import 'package:agriflow_admin/core/widgets/detail_row.dart';
import 'package:agriflow_admin/core/widgets/status_pill.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_item.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/services/seed_invoice_data.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/services/seed_invoice_downloader.dart';

class SeedPurchaseDetailSheet extends StatefulWidget {
  final SeedPurchaseItem item;
  final bool isActionInFlight;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  /// Invoice downloader seam. Tests pass a fake so no platform channel is
  /// touched; production falls back to [AndroidInvoiceDownloader].
  final InvoiceDownloader? downloader;

  const SeedPurchaseDetailSheet({
    super.key,
    required this.item,
    required this.isActionInFlight,
    required this.onApprove,
    required this.onReject,
    this.downloader,
  });

  @override
  State<SeedPurchaseDetailSheet> createState() => _SeedPurchaseDetailSheetState();
}

class _SeedPurchaseDetailSheetState extends State<SeedPurchaseDetailSheet> {
  bool _isDownloading = false;

  /// Generates the invoice PDF from the loaded row and saves it through the
  /// SAF system picker. Duplicate taps are ignored while in flight.
  Future<void> _downloadInvoice() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    final downloader = widget.downloader ?? AndroidInvoiceDownloader();
    InvoiceDownloadResult result;
    try {
      result = await downloader.download(
        data: SeedInvoiceData.fromItem(widget.item),
      );
    } catch (_) {
      result = const InvoiceDownloadResult(
        success: false,
        message: InvoiceMessages.saveFailure,
      );
    }

    if (!mounted) return;
    setState(() => _isDownloading = false);
    AppToast.show(context, result.message, isError: !result.success);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PURCHASE DETAILS',
                    style: AppTypography.eyebrow(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.invoiceNumber ?? (item.id.length > 8 ? item.id.substring(0, 8) : item.id),
                    style: AppTypography.titleMedium(color: AppColors.text).copyWith(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 16),

          // Farmer Info Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.canopy.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      item.displayName.isNotEmpty ? item.displayName[0].toUpperCase() : 'F',
                      style: AppTypography.titleMedium(color: AppColors.canopyDeep).copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        style: AppTypography.bodyMedium(color: AppColors.text).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.displayPhone.isNotEmpty)
                        Text(
                          item.displayPhone,
                          style: AppTypography.caption(color: AppColors.textMuted),
                        ),
                      Text(
                        'ID: ${item.farmerId.length > 8 ? item.farmerId.substring(0, 8) : item.farmerId}',
                        style: AppTypography.caption(color: AppColors.textFaint),
                      ),
                    ],
                  ),
                ),
                StatusPill.fromStatus(item.paymentStatus),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Order Breakdown Details
          DetailRow('Seed Item', item.displaySeed),
          if (item.displayVariety.isNotEmpty)
            DetailRow('Variety', item.displayVariety),
          DetailRow(
            'Quantity',
            '${item.quantityKg.toStringAsFixed(1)} kg (${(item.quantityKg / 100).toStringAsFixed(2)} Qtl)',
          ),
          DetailRow('Price per kg', '₹${item.pricePerKg.toStringAsFixed(2)}'),
          DetailRow('Total Amount', '₹${item.totalAmount.toStringAsFixed(2)}', emphasis: true),
          if (item.createdAt != null)
            DetailRow(
              'Order Date',
              AppDates.dateTimeLabel(item.createdAt!.toLocal()),
            ),

          const SizedBox(height: 24),

          // Actions
          if (item.isPending) ...[
            if (widget.isActionInFlight)
              const Center(
                child: CircularProgressIndicator(color: AppColors.canopy),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.bad,
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Reject Request', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.canopy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Approve & Mark Paid', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
          ],

          // Client-side invoice export (cross-ref finding 8 — parity with the
          // React admin's invoice download, no backend involved).
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isDownloading ? null : _downloadInvoice,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.canopy,
                      ),
                    )
                  : const Icon(Icons.download_outlined, size: 18),
              label: Text(
                _isDownloading ? 'Preparing invoice…' : 'Download invoice',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.adminNavyDeep,
                side: const BorderSide(color: AppColors.line),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
