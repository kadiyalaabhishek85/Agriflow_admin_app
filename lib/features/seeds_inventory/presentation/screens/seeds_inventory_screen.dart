import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../dashboard/shared/presentation/widgets/dashboard_state_views.dart';
import '../../domain/entities/seed_inventory_item.dart';
import '../controllers/seeds_inventory_controller.dart';
import '../widgets/add_edit_seed_sheet.dart';
import '../widgets/seed_inventory_card.dart';

/// Screen presenting the Seeds Inventory catalog.
/// Implements responsive layout, search, filter chips, and Admin-only mutations.
class SeedsInventoryScreen extends StatefulWidget {
  final SeedsInventoryController controller;
  final bool isAdmin;
  final VoidCallback onBack;

  const SeedsInventoryScreen({
    super.key,
    required this.controller,
    this.isAdmin = false,
    required this.onBack,
  });

  @override
  State<SeedsInventoryScreen> createState() => _SeedsInventoryScreenState();
}

class _SeedsInventoryScreenState extends State<SeedsInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load seeds if catalog not yet loaded
    if (widget.controller.allSeeds.isEmpty && !widget.controller.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.loadSeeds();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditSeedSheet(
        availableWarehouses: widget.controller.warehouses,
        errorProvider: () => widget.controller.errorMessage,
        onAdd: ({
          required name,
          required pricePerKg,
          required stockKg,
          cropType,
          variety,
          priceGradeA,
          priceGradeB,
          priceGradeC,
          maxOrderQuantityKg,
          warehouseIds,
          description,
          imageUrl,
        }) async {
          final ok = await widget.controller.addSeed(
            name: name,
            pricePerKg: pricePerKg,
            stockKg: stockKg,
            cropType: cropType,
            variety: variety,
            priceGradeA: priceGradeA,
            priceGradeB: priceGradeB,
            priceGradeC: priceGradeC,
            maxOrderQuantityKg: maxOrderQuantityKg,
            warehouseIds: warehouseIds,
            description: description,
            imageUrl: imageUrl,
          );
          if (ok && mounted) {
            AppToast.show(
              context,
              widget.controller.successMessage ?? 'Seed added successfully',
            );
          } else if (mounted && widget.controller.errorMessage != null) {
            AppToast.show(
              context,
              widget.controller.errorMessage!,
              isError: true,
            );
          }
          return ok;
        },
        onEdit: ({
          required seedId,
          name,
          cropType,
          variety,
          pricePerKg,
          priceGradeA,
          priceGradeB,
          priceGradeC,
          maxOrderQuantityKg,
          stockKg,
          warehouseIds,
          description,
          imageUrl,
          isActive,
        }) async =>
            false,
        onUploadImage: ({required fileBytes, required fileName, required contentType}) =>
            widget.controller.uploadImage(
          fileBytes: fileBytes,
          fileName: fileName,
          contentType: contentType,
        ),
      ),
    );
  }

  void _openEditSheet(SeedInventoryItem seed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditSeedSheet(
        seed: seed,
        availableWarehouses: widget.controller.warehouses,
        errorProvider: () => widget.controller.errorMessage,
        onAdd: ({
          required name,
          required pricePerKg,
          required stockKg,
          cropType,
          variety,
          priceGradeA,
          priceGradeB,
          priceGradeC,
          maxOrderQuantityKg,
          warehouseIds,
          description,
          imageUrl,
        }) async =>
            false,
        onEdit: ({
          required seedId,
          name,
          cropType,
          variety,
          pricePerKg,
          priceGradeA,
          priceGradeB,
          priceGradeC,
          maxOrderQuantityKg,
          stockKg,
          warehouseIds,
          description,
          imageUrl,
          isActive,
        }) async {
          final ok = await widget.controller.updateSeed(
            seedId: seedId,
            name: name,
            cropType: cropType,
            variety: variety,
            pricePerKg: pricePerKg,
            priceGradeA: priceGradeA,
            priceGradeB: priceGradeB,
            priceGradeC: priceGradeC,
            maxOrderQuantityKg: maxOrderQuantityKg,
            stockKg: stockKg,
            warehouseIds: warehouseIds,
            description: description,
            imageUrl: imageUrl,
            isActive: isActive,
          );
          if (ok && mounted) {
            AppToast.show(
              context,
              widget.controller.successMessage ?? 'Seed updated successfully',
            );
          } else if (mounted && widget.controller.errorMessage != null) {
            AppToast.show(
              context,
              widget.controller.errorMessage!,
              isError: true,
            );
          }
          return ok;
        },
        onUploadImage: ({required fileBytes, required fileName, required contentType}) =>
            widget.controller.uploadImage(
          fileBytes: fileBytes,
          fileName: fileName,
          contentType: contentType,
        ),
      ),
    );
  }

  void _confirmDelete(SeedInventoryItem seed) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Seed Product?',
          style: AppTypography.titleMedium(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "${seed.name}"? This action cannot be undone.',
          style: AppTypography.bodyMedium(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.button(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await widget.controller.deleteSeed(seed.id);
              if (ok && mounted) {
                AppToast.show(
                  context,
                  widget.controller.successMessage ?? 'Seed deleted successfully',
                );
              } else if (mounted && widget.controller.errorMessage != null) {
                AppToast.show(
                  context,
                  widget.controller.errorMessage!,
                  isError: true,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bad,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      SquircleIconButton(
                        icon: const Icon(Icons.chevron_left, size: 22),
                        onTap: widget.onBack,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock levels',
                              style: AppTypography.eyebrow(color: AppColors.textMuted),
                            ),
                            Text(
                              'Seeds Inventory',
                              style: AppTypography.titleLarge(
                                color: AppColors.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isAdmin)
                        ElevatedButton.icon(
                          onPressed: _openAddSheet,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Seed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.adminNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            textStyle: AppTypography.bodySmall(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: ctrl.setSearchQuery,
                      style: AppTypography.bodyMedium(color: AppColors.text),
                      decoration: InputDecoration(
                        hintText: 'Search seeds by name or variety...',
                        hintStyle: AppTypography.bodyMedium(color: AppColors.textFaint),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: AppColors.textFaint,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                color: AppColors.textFaint,
                                onPressed: () {
                                  _searchController.clear();
                                  ctrl.setSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                // Filter Chips (single line, scales cleanly without wrapping or clipping)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFilterChip(
                            label: 'All (${ctrl.totalSeedsCount})',
                            filterKey: 'all',
                            currentFilter: ctrl.currentFilter,
                            onSelected: () => ctrl.setFilter('all'),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            label: 'Active (${ctrl.activeSeedsCount})',
                            filterKey: 'active',
                            currentFilter: ctrl.currentFilter,
                            onSelected: () => ctrl.setFilter('active'),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            label: 'Low Stock (${ctrl.lowStockCount})',
                            filterKey: 'low_stock',
                            currentFilter: ctrl.currentFilter,
                            onSelected: () => ctrl.setFilter('low_stock'),
                            isWarning: ctrl.lowStockCount > 0,
                          ),
                          if (ctrl.inactiveSeedsCount > 0) ...[
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Inactive (${ctrl.inactiveSeedsCount})',
                              filterKey: 'inactive',
                              currentFilter: ctrl.currentFilter,
                              onSelected: () => ctrl.setFilter('inactive'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Main Content View
                Expanded(
                  child: _buildBody(ctrl),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String filterKey,
    required String currentFilter,
    required VoidCallback onSelected,
    bool isWarning = false,
  }) {
    final isSelected = currentFilter == filterKey;
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isWarning ? AppColors.bad : AppColors.adminNavy)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isWarning ? AppColors.badLight : AppColors.line),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall(
            color: isSelected
                ? Colors.white
                : (isWarning ? AppColors.bad : AppColors.textMuted),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ).copyWith(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildBody(SeedsInventoryController ctrl) {
    if (ctrl.isLoading && !ctrl.isRefreshing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.adminNavy),
      );
    }

    if (ctrl.errorMessage != null && ctrl.allSeeds.isEmpty) {
      return DashboardErrorView(
        message: ctrl.errorMessage!,
        onRetry: () => ctrl.loadSeeds(refresh: true),
      );
    }

    final items = ctrl.filteredSeeds;

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ctrl.loadSeeds(refresh: true),
        color: AppColors.adminNavy,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: EmptyStateView(
              title: ctrl.searchQuery.isNotEmpty
                  ? 'No seeds match your search'
                  : (ctrl.currentFilter == 'low_stock'
                      ? 'No low stock varieties'
                      : (ctrl.currentFilter == 'inactive'
                          ? 'No inactive seeds'
                          : (ctrl.currentFilter == 'active'
                              ? 'No active seeds in catalog'
                              : 'No seeds found in inventory'))),
              description: ctrl.searchQuery.isNotEmpty
                  ? 'Try searching by a different seed name or variety.'
                  : (ctrl.currentFilter == 'inactive'
                      ? 'Soft-deleted or inactive seeds will appear here.'
                      : 'Add seed products to populate the catalog.'),
              action: widget.isAdmin
                  ? ElevatedButton.icon(
                      onPressed: _openAddSheet,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Seed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminNavy,
                        foregroundColor: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ctrl.loadSeeds(refresh: true),
      color: AppColors.adminNavy,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final seed = items[index];
          return SeedInventoryCard(
            seed: seed,
            isAdmin: widget.isAdmin,
            onEdit: () => _openEditSheet(seed),
            onDelete: () => _confirmDelete(seed),
          );
        },
      ),
    );
  }
}
