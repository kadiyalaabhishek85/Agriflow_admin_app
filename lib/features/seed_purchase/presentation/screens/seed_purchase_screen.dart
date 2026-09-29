import 'package:flutter/material.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/constants/app_typography.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_state_views.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_item.dart';
import 'package:agriflow_admin/features/seed_purchase/presentation/controllers/seed_purchase_controller.dart';
import 'package:agriflow_admin/features/seed_purchase/presentation/widgets/seed_purchase_card.dart';
import 'package:agriflow_admin/features/seed_purchase/presentation/widgets/seed_purchase_detail_sheet.dart';

class SeedPurchaseScreen extends StatefulWidget {
  final SeedPurchaseController controller;
  final VoidCallback onBack;

  const SeedPurchaseScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  @override
  State<SeedPurchaseScreen> createState() => _SeedPurchaseScreenState();
}

class _SeedPurchaseScreenState extends State<SeedPurchaseScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.status == SeedPurchaseViewStatus.initial) {
        widget.controller.loadPurchases();
      }
    });
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
      widget.controller.loadMorePurchases();
    }
  }

  Future<void> _confirmAndReject(SeedPurchaseItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Seed Purchase?'),
        content: Text(
          'Are you sure you want to reject the purchase request for ${item.displayName} (${item.displaySeed})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bad,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await widget.controller.updateStatus(
        purchaseId: item.id,
        newStatus: 'failed',
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Purchase request ${item.invoiceNumber ?? item.id.substring(0, 6)} marked rejected'),
              backgroundColor: AppColors.bad,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.controller.errorMessage ?? 'Rejection failed'),
              backgroundColor: AppColors.bad,
            ),
          );
        }
      }
    }
  }

  Future<void> _approvePurchase(SeedPurchaseItem item) async {
    final success = await widget.controller.updateStatus(
      purchaseId: item.id,
      newStatus: 'paid',
    );
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase request ${item.invoiceNumber ?? item.id.substring(0, 6)} approved & marked paid!'),
            backgroundColor: AppColors.canopy,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.controller.errorMessage ?? 'Approval failed'),
            backgroundColor: AppColors.bad,
          ),
        );
      }
    }
  }

  void _openDetail(SeedPurchaseItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SeedPurchaseDetailSheet(
        item: item,
        isActionInFlight: widget.controller.actionInFlightId == item.id,
        onApprove: () {
          Navigator.of(ctx).pop();
          _approvePurchase(item);
        },
        onReject: () {
          Navigator.of(ctx).pop();
          _confirmAndReject(item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header matching HTML #screen-seed-purchase
                _buildHeader(),
                const SizedBox(height: 12),

                // Search Bar
                _buildSearchBar(),
                const SizedBox(height: 12),

                // Filter Chip Row matching HTML #sp-chip-row
                _buildFilterChips(),
                const SizedBox(height: 12),

                // Main Content
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.text),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage requests',
                  style: AppTypography.eyebrow(color: AppColors.textMuted),
                ),
                Text(
                  'Seed Purchase Requests',
                  style: AppTypography.titleLarge(color: AppColors.text).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onSubmitted: (val) => widget.controller.setSearch(val),
        decoration: InputDecoration(
          hintText: 'Search by farmer, seed or invoice...',
          hintStyle: AppTypography.bodySmall(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    widget.controller.setSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            borderSide: const BorderSide(color: AppColors.canopy, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('all', 'All'),
      ('pending', 'Pending'),
      ('paid', 'Paid'),
      ('failed', 'Failed'),
    ];

    final active = widget.controller.activeFilter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((f) {
          final isSelected = active == f.$1;
          final totalCount = isSelected ? widget.controller.pagination.total : null;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                totalCount != null && totalCount > 0 ? '${f.$2} ($totalCount)' : f.$2,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.text,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => widget.controller.setFilter(f.$1),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.canopy,
              side: BorderSide(
                color: isSelected ? AppColors.canopy : AppColors.line,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.controller.isLoading || widget.controller.status == SeedPurchaseViewStatus.initial) {
      return const DashboardLoadingView();
    }

    if (widget.controller.isError) {
      return DashboardErrorView(
        message: widget.controller.errorMessage ?? 'Failed to load seed purchases',
        onRetry: widget.controller.loadPurchases,
      );
    }

    final items = widget.controller.purchases;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'No seed purchases found',
                style: AppTypography.titleSmall(color: AppColors.text),
              ),
              const SizedBox(height: 4),
              Text(
                'No requests match the selected filter.',
                style: AppTypography.bodySmall(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.controller.refreshPurchases,
      color: AppColors.canopy,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: items.length + (widget.controller.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.canopy),
                ),
              ),
            );
          }

          final item = items[index];
          final isInFlight = widget.controller.actionInFlightId == item.id;

          return SeedPurchaseCard(
            item: item,
            isActionInFlight: isInFlight,
            onTap: () => _openDetail(item),
            onApprove: () => _approvePurchase(item),
            onReject: () => _confirmAndReject(item),
          );
        },
      ),
    );
  }
}
