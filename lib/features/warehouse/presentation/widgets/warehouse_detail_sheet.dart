import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/warehouse_controller.dart';
import 'add_inventory_sheet.dart';
import 'create_slot_sheet.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Comprehensive modal detail sheet showing live capacity metrics,
/// stored grain inventory breakdown, and farmer procurement intake booking slots.
class WarehouseDetailSheet extends StatefulWidget {
  final WarehouseController controller;

  const WarehouseDetailSheet({
    super.key,
    required this.controller,
  });

  @override
  State<WarehouseDetailSheet> createState() => _WarehouseDetailSheetState();
}

class _WarehouseDetailSheetState extends State<WarehouseDetailSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddInventory() {
    final wh = widget.controller.selectedWarehouse;
    if (wh == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => AddInventorySheet(
        warehouseId: wh.id,
        warehouseName: wh.name,
        availableCapacityKg: wh.availableCapacityKg,
        errorMessage: () => widget.controller.errorMessage,
        onAdd: ({
          required warehouseId,
          required grainType,
          required quantityKg,
        }) async {
          final ok = await widget.controller.addInventory(
            warehouseId: warehouseId,
            grainType: grainType,
            quantityKg: quantityKg,
          );
          if (ok && mounted) {
            AppToast.show(
              context,
              widget.controller.successMessage ?? 'Grain stock added.',
            );
          }
          return ok;
        },
      ),
    );
  }

  void _openCreateSlot() {
    final wh = widget.controller.selectedWarehouse;
    if (wh == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => CreateSlotSheet(
        warehouseId: wh.id,
        warehouseName: wh.name,
        errorMessage: () => widget.controller.errorMessage,
        onCreate: ({
          required warehouseId,
          required slotDate,
          required startTime,
          required endTime,
          required capacityKg,
        }) async {
          final ok = await widget.controller.createSlot(
            warehouseId: warehouseId,
            slotDate: slotDate,
            startTime: startTime,
            endTime: endTime,
            capacityKg: capacityKg,
          );
          if (ok && mounted) {
            AppToast.show(
              context,
              widget.controller.successMessage ?? 'Booking slot created.',
            );
          }
          return ok;
        },
      ),
    );
  }

  Future<void> _confirmDeleteSlot(String slotId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Booking Slot?'),
        content: const Text(
          'Are you sure you want to permanently delete this booking slot? This action cannot be undone.',
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
      await widget.controller.deleteSlot(slotId);
    }
  }

  Color _getBarColor(double occupancyPercent, bool isOverCapacity) {
    if (isOverCapacity) return AppColors.bad;
    if (occupancyPercent > 80.0) return AppColors.alert;
    if (occupancyPercent >= 60.0) return AppColors.amber;
    return AppColors.canopy;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final warehouse = widget.controller.selectedWarehouse;
        if (warehouse == null) {
          return const SizedBox.shrink();
        }

        final barColor = _getBarColor(warehouse.occupancyPercent, warehouse.isOverCapacity);
        final fillFraction = (warehouse.occupancyPercent / 100.0).clamp(0.0, 1.0);

        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.radiusLg)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              SheetDragHandle(),
              const SizedBox(height: 12),

              // Warehouse Header & Close Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.warehouse_outlined,
                          size: 22,
                          color: Color(0xFF6B4C9A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            warehouse.name,
                            style: AppTypography.titleMedium(
                              color: AppColors.text,
                            ).copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            warehouse.address,
                            style: AppTypography.caption(color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Capacity Summary Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Load',
                                style: AppTypography.caption(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${warehouse.currentLoadQtl.toStringAsFixed(1)} Qtl',
                                style: AppTypography.titleSmall(color: AppColors.text).copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total Capacity',
                                style: AppTypography.caption(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${warehouse.totalCapacityQtl.toStringAsFixed(1)} Qtl',
                                style: AppTypography.titleSmall(color: AppColors.text).copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 8,
                          width: double.infinity,
                          color: AppColors.line,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: fillFraction,
                            child: Container(
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Available: ${warehouse.availableCapacityQtl.toStringAsFixed(1)} Qtl (${(warehouse.availableCapacityKg).toStringAsFixed(0)} kg)',
                              style: AppTypography.caption(color: AppColors.textFaint).copyWith(
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${warehouse.occupancyPercent.toStringAsFixed(1)}% occupied',
                            style: AppTypography.caption(color: barColor).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Tab Bar: Grain Stock / Booking Slots
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.canopy,
                indicatorWeight: 3,
                labelColor: AppColors.canopyDeep,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'Grain Stock'),
                  Tab(text: 'Booking Slots'),
                ],
              ),

              // Tab Content Area
              Expanded(
                child: widget.controller.isLoadingDetails
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.canopy),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Grain Stock Breakdown
                          _buildInventoryTab(),

                          // Tab 2: Booking Slots
                          _buildSlotsTab(),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryTab() {
    final storedInventory = widget.controller.selectedInventory
        .where((item) => item.quantityKg > 0)
        .toList();
    final bookedStock = widget.controller.selectedBookedStock
        .where((item) => item.quantityKg > 0)
        .toList();
    final warehouse = widget.controller.selectedWarehouse!;
    final storedKg = storedInventory.fold<double>(0.0, (s, i) => s + i.quantityKg);
    final bookedKg = bookedStock.fold<double>(0.0, (s, i) => s + i.quantityKg);
    final unallocatedKg = (warehouse.currentLoadKg - storedKg - bookedKg);

    final displayEntries = <({
      String grainType,
      double quantityKg,
      double quantityQtl,
      String badge,
      bool isBooked,
    })>[
      ...storedInventory.map(
        (i) => (
          grainType: i.grainType,
          quantityKg: i.quantityKg,
          quantityQtl: i.quantityQtl,
          badge: '${i.quantityKg.toStringAsFixed(0)} kg stored',
          isBooked: false,
        ),
      ),
      ...bookedStock.map(
        (b) => (
          grainType: b.grainType,
          quantityKg: b.quantityKg,
          quantityQtl: b.quantityQtl,
          badge: '${b.quantityKg.toStringAsFixed(0)} kg · Booked Intake',
          isBooked: true,
        ),
      ),
      if (bookedStock.isEmpty && unallocatedKg > 0.01)
        (
          grainType: 'Booked / Reserved Grain',
          quantityKg: unallocatedKg,
          quantityQtl: unallocatedKg / 100.0,
          badge: '${unallocatedKg.toStringAsFixed(0)} kg · Active Load',
          isBooked: true,
        ),
    ];

    final loadError = widget.controller.errorMessage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Action button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Stored Commodities (${displayEntries.length})',
                  style: AppTypography.caption(color: AppColors.text).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.canopy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Inventory'),
                onPressed: _openAddInventory,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Inventory List
          Expanded(
            child: loadError != null && displayEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.bad),
                        const SizedBox(height: 8),
                        Text(
                          loadError,
                          style: AppTypography.bodySmall(color: AppColors.bad),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => widget.controller.selectWarehouse(warehouse),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : displayEntries.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textFaint),
                              const SizedBox(height: 8),
                              Text(
                                'No grain stock recorded.',
                                style: AppTypography.bodySmall(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "+ Add Inventory" to log incoming harvested crops.',
                                style: AppTypography.caption(color: AppColors.textFaint),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: displayEntries.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = displayEntries[index];
                          final pctOfCap = warehouse.totalCapacityKg > 0
                              ? (item.quantityKg / warehouse.totalCapacityKg * 100).toStringAsFixed(1)
                              : '0.0';

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: item.isBooked
                                              ? AppColors.infoBg
                                              : AppColors.surfaceAlt,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          item.isBooked
                                              ? Icons.event_available_outlined
                                              : Icons.grain,
                                          size: 18,
                                          color: item.isBooked
                                              ? AppColors.adminNavyLight
                                              : AppColors.canopy,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.grainType,
                                              style: AppTypography.bodySmall(color: AppColors.text).copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              item.badge,
                                              style: AppTypography.caption(color: AppColors.textMuted).copyWith(
                                                fontSize: 10.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item.quantityQtl.toStringAsFixed(1)} Qtl',
                                      style: AppTypography.bodySmall(color: AppColors.canopyDeep).copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '$pctOfCap% of total cap',
                                      style: AppTypography.caption(color: AppColors.textFaint).copyWith(
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsTab() {
    final slots = widget.controller.selectedSlots;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Action button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Intake Windows (${slots.length})',
                  style: AppTypography.caption(color: AppColors.text).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.canopy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Slot'),
                onPressed: _openCreateSlot,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Slots List
          Expanded(
            child: slots.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 40, color: AppColors.textFaint),
                          const SizedBox(height: 8),
                          Text(
                            'No intake booking slots created.',
                            style: AppTypography.bodySmall(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "+ Add Slot" to open a delivery window for farmers.',
                            style: AppTypography.caption(color: AppColors.textFaint),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: slots.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final slot = slots[index];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date, Time & Status Pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        slot.slotDate,
                                        style: AppTypography.bodySmall(color: AppColors.text).copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        slot.timeRangeLabel,
                                        style: AppTypography.caption(color: AppColors.textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusPill.fromStatus(slot.status),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Booked vs Total Capacity
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Booked: ${slot.bookedQtl.toStringAsFixed(1)} / ${slot.capacityQtl.toStringAsFixed(1)} Qtl (${slot.occupancyPercent.toStringAsFixed(0)}%)',
                                    style: AppTypography.caption(color: AppColors.textFaint).copyWith(
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (slot.isActive) ...[
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () => widget.controller.cancelSlot(slot.id),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: AppColors.amber,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.alert),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                      onPressed: () => _confirmDeleteSlot(slot.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
