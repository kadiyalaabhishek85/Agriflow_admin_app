import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/bank_change_request_item.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Modal bottom sheet for Admin review of farmer bank change requests.
class BankChangeRequestsSheet extends StatefulWidget {
  final List<BankChangeRequestItem> requests;
  final bool isLoading;
  final String? errorMessage;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function()? onLoadMore;
  final Future<void> Function() onRefresh;
  final Future<bool> Function({
    required String requestId,
    required bool approve,
    String? adminNotes,
  }) onReview;

  const BankChangeRequestsSheet({
    super.key,
    required this.requests,
    required this.isLoading,
    this.errorMessage,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    required this.onRefresh,
    required this.onReview,
  });

  @override
  State<BankChangeRequestsSheet> createState() => _BankChangeRequestsSheetState();
}

class _BankChangeRequestsSheetState extends State<BankChangeRequestsSheet> {
  final ScrollController _scrollController = ScrollController();
  String? _processingId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || widget.onLoadMore == null) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      widget.onLoadMore!();
    }
  }

  Future<void> _handleReview(String id, bool approve) async {
    setState(() => _processingId = id);
    await widget.onReview(requestId: id, approve: approve);
    if (mounted) {
      setState(() => _processingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                children: [
                  SheetDragHandle(margin: const EdgeInsets.only(bottom: 12)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'ADMIN AUDIT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.textFaint,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Bank Change Requests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                      SquircleIconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        size: 32,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),

            if (widget.errorMessage != null)
              Container(
                key: const Key('bank_requests_error'),
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.badBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.bad.withValues(alpha: 0.35)),
                ),
                child: Text(
                  widget.errorMessage!,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.bad),
                ),
              ),

            // Content
            Expanded(
              child: widget.isLoading && widget.requests.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.canopy),
                    )
                  : widget.requests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.account_balance_outlined, size: 40, color: AppColors.textFaint),
                              SizedBox(height: 8),
                              Text(
                                'No bank change requests',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: widget.onRefresh,
                          color: AppColors.canopy,
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount:
                                widget.requests.length + (widget.hasMore ? 1 : 0),
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index >= widget.requests.length) {
                                if (!widget.isLoadingMore) {
                                  return const SizedBox.shrink();
                                }
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.canopy,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final req = widget.requests[index];
                              final isProcessing = _processingId == req.id;

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFAF7),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            req.displayFarmerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: AppColors.text,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        StatusPill.fromStatus(req.status),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Bank: ${req.bankName ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                    Text(
                                      'A/C: ${req.accountNumber ?? 'N/A'} · IFSC: ${req.ifscCode ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                    if (req.upiId != null && req.upiId!.isNotEmpty) ...[
                                      Text(
                                        'UPI: ${req.upiId}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      'Requested: ${req.formattedRequestedDate}',
                                      style: const TextStyle(fontSize: 10.5, color: AppColors.textFaint),
                                    ),

                                    if (req.isPending) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: isProcessing ? null : () => _handleReview(req.id, false),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.bad,
                                                side: const BorderSide(color: AppColors.badBg),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                              child: const Text('Reject', style: TextStyle(fontSize: 12)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: isProcessing ? null : () => _handleReview(req.id, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.good,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                elevation: 0,
                                              ),
                                              child: isProcessing
                                                  ? const SizedBox(
                                                      width: 14,
                                                      height: 14,
                                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                    )
                                                  : const Text('Approve', style: TextStyle(fontSize: 12)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
