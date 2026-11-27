import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/billing_transaction_item.dart';
import '../controllers/billing_controller.dart';
import '../widgets/billing_card.dart';
import '../widgets/billing_metrics_grid.dart';
import '../widgets/billing_receipt_sheet.dart';
import '../widgets/log_transaction_sheet.dart';

/// Main screen for Billing & Invoices (Payments Desk).
class BillingScreen extends StatefulWidget {
  final BillingController controller;
  final VoidCallback onBack;
  final bool isManagerRole;

  const BillingScreen({
    super.key,
    required this.controller,
    required this.onBack,
    this.isManagerRole = false,
  });

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.controller.addListener(_onControllerUpdate);

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadFarmers();
      widget.controller.loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {});
    widget.controller.previewSearch(val);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.controller.setSearchQuery(val);
      }
    });
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.controller.loadMoreTransactions();
    }
  }

  void _showSettleDialog(BillingTransactionItem item) {
    final descController = TextEditingController(
      text: 'Settled via cash/bank transfer',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.good, size: 24),
              const SizedBox(width: 8),
              Text(
                'Settle Payment',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to mark ${item.displayInvoiceNumber} (${item.displayAmount}) as completed/paid?',
                style: GoogleFonts.manrope(fontSize: 13, color: AppColors.text),
              ),
              const SizedBox(height: 12),
              Text(
                'Payment Note / Description:',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  hintText: 'e.g. NEFT Reference #12345',
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final success = await widget.controller.payTransaction(
                  item.id,
                  description: descController.text.trim(),
                );

                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Transaction marked as paid successfully',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.good,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (widget.controller.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.controller.errorMessage!),
                        backgroundColor: AppColors.bad,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.canopy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Confirm Settle',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReceipt(BillingTransactionItem item) {
    BillingReceiptSheet.show(
      context,
      item: item,
      onPay: item.isPending ? () => _showSettleDialog(item) : null,
    );
  }

  Future<void> _showAddBillSheet() async {
    if (widget.controller.farmers.isEmpty) {
      await widget.controller.loadFarmers();
      if (!mounted) return;
    }

    final created = await LogTransactionSheet.show(
      context,
      farmers: widget.controller.farmers,
      onSubmit: ({
        required farmerId,
        required amount,
        required direction,
        required referenceType,
        description,
      }) async {
        final success = await widget.controller.createTransaction(
          farmerId: farmerId,
          amount: amount,
          direction: direction,
          referenceType: referenceType,
          description: description,
        );
        if (success) return null;
        return widget.controller.errorMessage ?? 'Failed to record transaction';
      },
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transaction recorded successfully',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.good,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: widget.controller.fromDate != null && widget.controller.toDate != null
          ? DateTimeRange(start: widget.controller.fromDate!, end: widget.controller.toDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.canopy,
              onPrimary: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      widget.controller.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshTransactions,
          color: AppColors.canopy,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top Bar with Back and Add Bill Action
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
                            onPressed: widget.onBack,
                            splashRadius: 24,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payments Desk',
                                  style: GoogleFonts.manrope(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Billing, Invoices & Settlements',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _showAddBillSheet,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: Text(
                              'Add Bill',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.canopy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Metrics Grid
                      BillingMetricsGrid(
                        metrics: controller.metrics,
                        isLoading: controller.isLoading && controller.transactions.isEmpty,
                      ),
                      const SizedBox(height: 14),

                      // Search Input
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: _onSearchChanged,
                          onSubmitted: (val) {
                            _searchDebounce?.cancel();
                            controller.setSearchQuery(val);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by invoice #, memo, farmer ID...',
                            hintStyle: GoogleFonts.manrope(fontSize: 13, color: AppColors.textFaint),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                                    onPressed: () {
                                      _searchDebounce?.cancel();
                                      _searchController.clear();
                                      setState(() {});
                                      controller.setSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status Tabs / Chips — single fitted line so all statuses stay visible
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _FilterChip(
                                key: const ValueKey('billing-filter-all'),
                                label: 'All',
                                isSelected: controller.statusFilter == 'all',
                                onTap: () => controller.setStatusFilter('all'),
                              ),
                              const SizedBox(width: 6),
                              _FilterChip(
                                key: const ValueKey('billing-filter-completed'),
                                label: 'Completed (Paid)',
                                isSelected: controller.statusFilter == 'completed',
                                onTap: () => controller.setStatusFilter('completed'),
                              ),
                              const SizedBox(width: 6),
                              _FilterChip(
                                key: const ValueKey('billing-filter-pending'),
                                label: 'Pending',
                                isSelected: controller.statusFilter == 'pending',
                                onTap: () => controller.setStatusFilter('pending'),
                              ),
                              const SizedBox(width: 6),
                              _FilterChip(
                                key: const ValueKey('billing-filter-failed'),
                                label: 'Failed',
                                isSelected: controller.statusFilter == 'failed',
                                onTap: () => controller.setStatusFilter('failed'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Secondary Filter Row (Category Dropdown, Direction Dropdown, Date Picker)
                      Row(
                        children: [
                          // Type filter
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  isExpanded: true,
                                  value: controller.referenceTypeFilter,
                                  style: GoogleFonts.manrope(fontSize: 11.5, color: AppColors.text),
                                  hint: Text(
                                    'Type: All',
                                    style: GoogleFonts.manrope(fontSize: 11.5, color: AppColors.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('Type: All', overflow: TextOverflow.ellipsis)),
                                    DropdownMenuItem(value: 'seed_purchase', child: Text('Seed Sale', overflow: TextOverflow.ellipsis)),
                                    DropdownMenuItem(value: 'grain_sale', child: Text('Grain Payout', overflow: TextOverflow.ellipsis)),
                                    DropdownMenuItem(value: 'billing', child: Text('Service Bill', overflow: TextOverflow.ellipsis)),
                                    DropdownMenuItem(value: 'other', child: Text('Other', overflow: TextOverflow.ellipsis)),
                                  ],
                                  onChanged: (val) => controller.setReferenceTypeFilter(val),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Direction filter
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  isExpanded: true,
                                  value: controller.directionFilter,
                                  style: GoogleFonts.manrope(fontSize: 11.5, color: AppColors.text),
                                  hint: Text(
                                    'Flow: All',
                                    style: GoogleFonts.manrope(fontSize: 11.5, color: AppColors.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('Flow: All', overflow: TextOverflow.ellipsis)),
                                    DropdownMenuItem(value: 'credit', child: Text('Credits (In)', overflow: TextOverflow.ellipsis)),
                                    DropdownMenuItem(value: 'debit', child: Text('Debits (Out)', overflow: TextOverflow.ellipsis)),
                                  ],
                                  onChanged: (val) => controller.setDirectionFilter(val),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Date Range Filter Button
                          Flexible(
                            flex: 2,
                            fit: FlexFit.loose,
                            child: InkWell(
                              onTap: _pickDateRange,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: controller.fromDate != null
                                      ? AppColors.canopyLight
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: controller.fromDate != null
                                        ? AppColors.canopy
                                        : AppColors.line,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 14,
                                        color: controller.fromDate != null
                                            ? AppColors.canopyDeep
                                            : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (controller.fromDate != null && controller.toDate != null)
                                            ? '${DateFormat('dd/MM').format(controller.fromDate!)}-${DateFormat('dd/MM').format(controller.toDate!)}'
                                            : 'Dates',
                                        maxLines: 1,
                                        style: GoogleFonts.manrope(
                                          fontSize: 11.5,
                                          fontWeight: controller.fromDate != null
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: controller.fromDate != null
                                              ? AppColors.canopyDeep
                                              : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (controller.fromDate != null ||
                              controller.referenceTypeFilter != null ||
                              controller.directionFilter != null ||
                              controller.statusFilter != 'all') ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                controller.clearFilters();
                              },
                              tooltip: 'Reset Filters',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              splashRadius: 18,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Transaction List Content
              if (controller.isLoading && controller.transactions.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: AppLoadingView(message: 'Loading transactions & invoices...'),
                  ),
                )
              else if (controller.errorMessage != null && controller.transactions.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: AppErrorView(
                      message: controller.errorMessage!,
                      onRetry: controller.loadTransactions,
                    ),
                  ),
                )
              else if (controller.transactions.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: EmptyStateView(
                      title: 'No Transactions Found',
                      description: 'No billing or payment records match your active search or filter criteria.',
                      icon: Icon(Icons.receipt_long_outlined, size: 28, color: AppColors.textFaint),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == controller.transactions.length) {
                          return controller.isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.canopy,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox(height: 16);
                        }

                        final item = controller.transactions[index];
                        return BillingCard(
                          item: item,
                          onTap: () => _showReceipt(item),
                          onPay: item.isPending ? () => _showSettleDialog(item) : null,
                        );
                      },
                      childCount: controller.transactions.length + (controller.pagination.hasMore ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.canopy : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.canopy : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
