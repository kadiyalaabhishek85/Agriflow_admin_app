import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/services/android_receipt_downloader.dart';
import '../../domain/entities/billing_transaction_item.dart';
import '../../domain/receipt/billing_receipt_data.dart';
import '../../domain/services/receipt_downloader.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Modal bottom sheet displaying a verified Invoice / Transaction Receipt.
class BillingReceiptSheet extends StatefulWidget {
  final BillingTransactionItem item;
  final VoidCallback? onPay;

  /// Injectable export service; defaults to the production Android
  /// downloader. Tests pass a fake so no platform channel is touched.
  final ReceiptDownloader? downloader;

  const BillingReceiptSheet({
    super.key,
    required this.item,
    this.onPay,
    this.downloader,
  });

  static Future<void> show(
    BuildContext context, {
    required BillingTransactionItem item,
    VoidCallback? onPay,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BillingReceiptSheet(item: item, onPay: onPay),
    );
  }

  @override
  State<BillingReceiptSheet> createState() => _BillingReceiptSheetState();
}

class _BillingReceiptSheetState extends State<BillingReceiptSheet> {
  bool _isDownloading = false;

  BillingReceiptData get _data => BillingReceiptData.from(widget.item);

  void _copyReceiptToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _data.toCopyText()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Receipt copied to clipboard',
              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.canopyDeep,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Generates the receipt PDF from verified data and saves it through the
  /// SAF system picker. Duplicate taps are ignored while in flight.
  Future<void> _downloadReceipt() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    final downloader = widget.downloader ?? AndroidReceiptDownloader();
    ReceiptDownloadResult result;
    try {
      result = await downloader.download(data: _data);
    } catch (_) {
      result = const ReceiptDownloadResult(
        success: false,
        message: ReceiptMessages.saveFailure,
      );
    }

    if (!mounted) return;
    setState(() => _isDownloading = false);

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.message,
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (result.success && result.location != null) ...[
              const SizedBox(height: 2),
              Text(
                result.location!,
                style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        backgroundColor: result.success ? AppColors.canopyDeep : AppColors.bad,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.item.isCredit;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      // Scrollable so the Download/Copy actions stay reachable on short
      // screens (320x568) even when the receipt content exceeds the height.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Drag handle
          SheetDragHandle(),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.canopyLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.canopy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Invoice Receipt',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            'AgriFlow Financial Desk',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: isCredit ? AppColors.goodBg : AppColors.badBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCredit
                    ? AppColors.good.withValues(alpha: 0.2)
                    : AppColors.bad.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      size: 18,
                      color: isCredit ? AppColors.good : AppColors.bad,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCredit ? 'CREDIT / RECEIVED' : 'DEBIT / PAYOUT',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isCredit ? AppColors.good : AppColors.bad,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.item.displayAmount,
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                StatusPill.fromStatus(widget.item.status),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Receipt Metadata Fields
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                _ReceiptRow(label: 'Invoice Number', value: widget.item.displayInvoiceNumber),
                const Divider(height: 14, color: AppColors.line),
                _ReceiptRow(label: 'Date & Time', value: widget.item.formattedDate),
                const Divider(height: 14, color: AppColors.line),
                _ReceiptRow(label: 'Category', value: widget.item.displayReferenceType),
                const Divider(height: 14, color: AppColors.line),
                _ReceiptRow(label: 'Farmer / Account', value: widget.item.displayFarmerName),
                if (widget.item.enrichedFarmerPhone != null) ...[
                  const Divider(height: 14, color: AppColors.line),
                  _ReceiptRow(label: 'Phone', value: widget.item.enrichedFarmerPhone!),
                ],
                if (widget.item.referenceId != null) ...[
                  const Divider(height: 14, color: AppColors.line),
                  _ReceiptRow(
                    label: 'Reference ID',
                    value: widget.item.referenceId!.length > 12
                        ? widget.item.referenceId!.substring(0, 12)
                        : widget.item.referenceId!,
                  ),
                ],
                if (widget.item.description != null && widget.item.description!.isNotEmpty) ...[
                  const Divider(height: 14, color: AppColors.line),
                  _ReceiptRow(label: 'Description', value: widget.item.description!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions — Copy and Download are both available at all times;
          // Settle appears only for pending transactions.
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyReceiptToClipboard(context),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(
                    'Copy Receipt',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadReceipt,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, size: 16),
                  label: Text(
                    _isDownloading ? 'Saving...' : 'Download Receipt',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.canopy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.canopy.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          if (widget.item.isPending && widget.onPay != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onPay!();
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(
                  'Settle / Pay',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.canopy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
