import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../domain/entities/warehouse_item.dart';
import '../controllers/warehouse_controller.dart';
import '../widgets/add_edit_warehouse_sheet.dart';
import '../widgets/warehouse_card.dart';
import '../widgets/warehouse_detail_sheet.dart';

/// Screen presenting the Warehouse Management module for Admin and Manager roles.
class WarehouseScreen extends StatefulWidget {
  final WarehouseController controller;
  final bool isAdmin;
  final VoidCallback? onBack;

  const WarehouseScreen({
    super.key,
    required this.controller,
    this.isAdmin = false,
    this.onBack,
  });

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.controller.allWarehouses.isEmpty && !widget.controller.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.loadWarehouses();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddWarehouseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditWarehouseSheet(
        onSave: ({
          required name,
          required address,
          required totalCapacityKg,
          location,
          contactNumber,
          managerId,
          isActive,
        }) async {
          final ok = await widget.controller.createWarehouse(
            name: name,
            address: address,
            totalCapacityKg: totalCapacityKg,
            location: location,
            contactNumber: contactNumber,
            managerId: managerId,
          );
          if (ok && mounted) {
            AppToast.show(
              context,
              widget.controller.successMessage ?? 'Warehouse created successfully.',
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
      ),
    );
  }

  void _openEditWarehouseSheet(WarehouseItem warehouse) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditWarehouseSheet(
        warehouse: warehouse,
        onSave: ({
          required name,
          required address,
          required totalCapacityKg,
          location,
          contactNumber,
          managerId,
          isActive,
        }) async {
          final ok = await widget.controller.updateWarehouse(
            warehouseId: warehouse.id,
            name: name,
            address: address,
            totalCapacityKg: totalCapacityKg,
            location: location,
            contactNumber: contactNumber,
            managerId: managerId,
            isActive: isActive,
          );
          if (ok && mounted) {
            AppToast.show(
              context,
              widget.controller.successMessage ?? 'Warehouse updated successfully.',
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
      ),
    );
  }

  Future<void> _confirmDeleteWarehouse(WarehouseItem warehouse) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Warehouse?'),
        content: Text(
          'Are you sure you want to permanently delete "${warehouse.name}"? This will remove all associated slots and inventory mappings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alert,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await widget.controller.deleteWarehouse(warehouse.id);
      if (ok && mounted) {
        AppToast.show(
          context,
          widget.controller.successMessage ?? 'Warehouse deleted.',
        );
      } else if (mounted && widget.controller.errorMessage != null) {
        AppToast.show(
          context,
          widget.controller.errorMessage!,
          isError: true,
        );
      }
    }
  }

  void _openDetailSheet(WarehouseItem warehouse) {
    widget.controller.selectWarehouse(warehouse);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WarehouseDetailSheet(
        controller: widget.controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final warehouses = widget.controller.filteredWarehouses;

        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: widget.isAdmin
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.canopy,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text('Add Warehouse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: _openAddWarehouseSheet,
                )
              : null,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.canopy,
              onRefresh: () => widget.controller.loadWarehouses(refresh: true),
              child: CustomScrollView(
                slivers: [
                  // App Bar / Top Navigation Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          SquircleIconButton.back(
                            onTap: widget.onBack,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Storage locations',
                                  style: AppTypography.eyebrow(color: AppColors.canopy),
                                ),
                                Text(
                                  'Warehouses',
                                  style: AppTypography.displayMedium(color: AppColors.text).copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.isAdmin) ...[
                            SquircleIconButton(
                              icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                              backgroundColor: AppColors.canopy,
                              onTap: _openAddWarehouseSheet,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppColors.radiusSm),
                          border: Border.all(color: AppColors.line),
                          boxShadow: AppColors.shadowSm,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: widget.controller.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Search warehouse by name, city, location...',
                            hintStyle: AppTypography.bodySmall(color: AppColors.textFaint),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      widget.controller.setSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Metrics Summary Banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppColors.radiusMd),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildMetricItem(
                                'Facilities',
                                '${widget.controller.totalWarehousesCount}',
                                AppColors.text,
                              ),
                            ),
                            _buildMetricDivider(),
                            Expanded(
                              child: _buildMetricItem(
                                'Total Cap',
                                '${widget.controller.totalCapacityQtl.toStringAsFixed(0)} Qtl',
                                AppColors.canopyDeep,
                              ),
                            ),
                            _buildMetricDivider(),
                            Expanded(
                              child: _buildMetricItem(
                                'Current Load',
                                '${widget.controller.totalLoadQtl.toStringAsFixed(0)} Qtl',
                                AppColors.amber,
                              ),
                            ),
                            _buildMetricDivider(),
                            Expanded(
                              child: _buildMetricItem(
                                'Avg Occupancy',
                                '${widget.controller.averageOccupancyPercent.toStringAsFixed(0)}%',
                                widget.controller.averageOccupancyPercent > 80.0
                                    ? AppColors.alert
                                    : AppColors.forest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Filter Chips Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'All Locations (${widget.controller.totalWarehousesCount})'),
                            const SizedBox(width: 8),
                            _buildFilterChip('active', 'Active (${widget.controller.activeWarehousesCount})'),
                            const SizedBox(width: 8),
                            _buildFilterChip('near_full', 'Near/Over Full (${widget.controller.nearFullCount})'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Error Banner
                  if (widget.controller.errorMessage != null && !widget.controller.isLoading) ...[
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.badBg,
                          borderRadius: BorderRadius.circular(AppColors.radiusSm),
                          border: Border.all(color: AppColors.bad.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.bad, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.controller.errorMessage!,
                                style: AppTypography.caption(color: AppColors.bad),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: AppColors.bad, size: 18),
                              onPressed: () => widget.controller.loadWarehouses(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Loading Indicator
                  if (widget.controller.isLoading) ...[
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.canopy),
                      ),
                    ),
                  ] else if (warehouses.isEmpty) ...[
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F2F7),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.warehouse_outlined,
                                  size: 32,
                                  color: Color(0xFF6B4C9A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Warehouses Found',
                                style: AppTypography.titleMedium(color: AppColors.text).copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchController.text.isNotEmpty
                                    ? 'No warehouses match "${_searchController.text}".'
                                    : 'No warehouse facilities are currently registered on file.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall(color: AppColors.textMuted),
                              ),
                              if (widget.isAdmin) ...[
                                const SizedBox(height: 18),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.canopy,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppColors.radiusSm),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Warehouse'),
                                  onPressed: _openAddWarehouseSheet,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Warehouses List
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final warehouse = warehouses[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: WarehouseCard(
                                warehouse: warehouse,
                                isAdmin: widget.isAdmin,
                                onTap: () => _openDetailSheet(warehouse),
                                onEdit: () => _openEditWarehouseSheet(warehouse),
                                onDelete: () => _confirmDeleteWarehouse(warehouse),
                              ),
                            );
                          },
                          childCount: warehouses.length,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTypography.titleSmall(color: color).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: AppTypography.caption(color: AppColors.textMuted).copyWith(
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.line,
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = widget.controller.currentFilter == key;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => widget.controller.setFilter(key),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.canopyLight.withValues(alpha: 0.3),
      checkmarkColor: AppColors.canopyDeep,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.canopyDeep : AppColors.textMuted,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.canopy : AppColors.line,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}
