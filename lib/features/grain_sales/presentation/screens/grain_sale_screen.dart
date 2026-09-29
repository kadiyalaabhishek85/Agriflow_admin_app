import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../dashboard/shared/presentation/widgets/dashboard_state_views.dart';
import '../../domain/entities/grain_sale_item.dart';
import '../controllers/grain_sale_controller.dart';
import '../widgets/grain_sale_card.dart';
import '../widgets/grain_sale_detail_sheet.dart';
import '../widgets/log_received_crop_sheet.dart';
import '../widgets/update_yield_sheet.dart';

/// Screen displaying Grain Sales & Crop Procurement for Admin and Manager roles.
class GrainSaleScreen extends StatefulWidget {
  final GrainSaleController controller;
  final VoidCallback onBack;
  final bool isManagerRole;

  const GrainSaleScreen({
    super.key,
    required this.controller,
    required this.onBack,
    this.isManagerRole = false,
  });

  @override
  State<GrainSaleScreen> createState() => _GrainSaleScreenState();
}

class _GrainSaleScreenState extends State<GrainSaleScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.controller.loadFarmers();
    if (widget.controller.sales.isEmpty && !widget.controller.isLoading) {
      widget.controller.loadSales();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      widget.controller.loadMoreSales();
    }
  }

  void _openDetailSheet(BuildContext context, dynamic item) {
    final saleItem = item is GrainSaleItem ? item : null;
    if (saleItem == null) return;

    GrainSaleDetailSheet.show(
      context: context,
      item: saleItem,
      isSubmitting: widget.controller.isSubmitting,
      onReview: () async {
        final success = await widget.controller.reviewGrainSale(
          saleId: saleItem.id,
          approve: true,
        );
        if (!context.mounted) return;
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.canopyDeep,
              content: Text('Grain sale reviewed and approved successfully!'),
            ),
          );
        } else {
          final error = widget.controller.errorMessage ?? 'Failed to review and approve sale.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.alert,
              content: Text(error),
            ),
          );
        }
      },
      onReject: () async {
        final success = await widget.controller.reviewGrainSale(
          saleId: saleItem.id,
          approve: false,
          rejectionReason: 'Rejected during manager inspection',
        );
        if (!context.mounted) return;
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.alert,
              content: Text('Grain procurement rejected.'),
            ),
          );
        } else {
          final error = widget.controller.errorMessage ?? 'Failed to reject sale.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.alert,
              content: Text(error),
            ),
          );
        }
      },
      onPay: () async {
        final success = await widget.controller.payGrainSale(saleItem.id);
        if (!context.mounted) return;
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.canopyDeep,
              content: Text('Payment approved and marked as paid!'),
            ),
          );
        } else {
          final error = widget.controller.errorMessage ?? 'Failed to mark payment as paid.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.alert,
              content: Text(error),
            ),
          );
        }
      },
      onUpdateYield: () async {
        final updated = await UpdateYieldSheet.show(
          context: context,
          goodMaterialKg: saleItem.goodMaterialKg,
          wastageKg: saleItem.wastageKg,
          isSubmitting: widget.controller.isSubmitting,
          errorMessage: () => widget.controller.errorMessage,
          onSubmit: ({
            required goodMaterialKg,
            required wastageKg,
          }) {
            return widget.controller.updateGrainYield(
              saleId: saleItem.id,
              goodMaterialKg: goodMaterialKg,
              wastageKg: wastageKg,
            );
          },
        );
        if (updated == true && context.mounted) {
          // Yield sheet already popped itself; close the stale detail sheet
          // so the refreshed list values are shown on reopen.
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.canopyDeep,
              content: Text('Yield quantities updated.'),
            ),
          );
        }
      },
    );
  }

  void _openLogCropSheet(BuildContext context) {
    LogReceivedCropSheet.show(
      context: context,
      farmers: widget.controller.farmers,
      isSubmitting: widget.controller.isSubmitting,
      onSubmit: ({
        required farmerId,
        required grainType,
        required grade,
        required rawMaterialKg,
        required goodMaterialKg,
        required wastageKg,
      }) async {
        final ok = await widget.controller.procureCrop(
          farmerId: farmerId,
          grainType: grainType,
          grade: grade,
          rawMaterialKg: rawMaterialKg,
          goodMaterialKg: goodMaterialKg,
          wastageKg: wastageKg,
        );
        if (ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crop procurement logged successfully!')),
          );
        }
        return ok;
      },
    );
  }

  Widget _buildFilterChip(String label, String filterKey) {
    final isActive = widget.controller.currentFilter == filterKey;
    return GestureDetector(
      key: Key('grain_chip_$filterKey'),
      onTap: () => widget.controller.setFilter(filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.canopyDeep : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.canopyDeep : AppColors.line,
          ),
          boxShadow: isActive ? AppColors.shadowSm : null,
        ),
        child: Text(
          label,
          style: AppTypography.caption(
            color: isActive ? Colors.white : AppColors.textMuted,
          ).copyWith(fontWeight: isActive ? FontWeight.w800 : FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row matching HTML specification
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: widget.onBack,
                            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!widget.isManagerRole) ...[
                                  Text(
                                    'PROCUREMENT DESK',
                                    style: AppTypography.eyebrow(color: AppColors.canopyDeep),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  widget.isManagerRole ? 'Crop Procurement' : 'Grain Sales',
                                  style: AppTypography.titleLarge(color: AppColors.text),
                                ),
                                if (widget.isManagerRole) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Log and manage crops received from farmers',
                                    style: AppTypography.bodySmall(color: AppColors.textMuted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openLogCropSheet(context),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Log Crop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.canopyDeep,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Live Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => controller.setSearchQuery(val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search farmer or grain type...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    controller.setSearchQuery('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surfaceAlt,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppColors.radiusMd),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppColors.radiusMd),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter Chips Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', 'all'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Pending', 'pending'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Received', 'received'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Approved', 'approved'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Rejected', 'rejected'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Paid', 'paid'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content Body: Loading, Error, Empty, or Populated List
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (controller.isLoading) {
                        return const DashboardLoadingView();
                      }

                      if (controller.errorMessage != null && controller.sales.isEmpty) {
                        return DashboardErrorView(
                          message: controller.errorMessage!,
                          onRetry: () => controller.loadSales(),
                        );
                      }

                      if (controller.sales.isEmpty) {
                        return DashboardEmptyView(
                          title: 'No Grain Sales Found',
                          message: 'No procurement records match the current filter or search.',
                          onRefresh: () => controller.refreshSales(),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => controller.refreshSales(),
                        color: AppColors.canopyDeep,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: controller.sales.length + (controller.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index >= controller.sales.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }

                            final item = controller.sales[index];
                            return GrainSaleCard(
                              item: item,
                              onTap: () => _openDetailSheet(context, item),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
