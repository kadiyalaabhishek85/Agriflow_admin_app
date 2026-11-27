import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/constants/app_typography.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_item.dart';
import 'package:agriflow_admin/features/booking_slot/presentation/controllers/booking_controller.dart';
import 'package:agriflow_admin/features/booking_slot/presentation/widgets/booking_card.dart';
import 'package:agriflow_admin/features/booking_slot/presentation/widgets/booking_detail_sheet.dart';
import 'package:agriflow_admin/features/booking_slot/presentation/widgets/date_selector_strip.dart';
import 'package:agriflow_admin/features/booking_slot/presentation/widgets/inspect_booking_sheet.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_state_views.dart';

class BookingSlotScreen extends StatefulWidget {
  final BookingController controller;
  final VoidCallback onBack;

  const BookingSlotScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  @override
  State<BookingSlotScreen> createState() => _BookingSlotScreenState();
}

class _BookingSlotScreenState extends State<BookingSlotScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.status == BookingViewStatus.initial) {
        widget.controller.loadBookings();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {});
    widget.controller.previewSearch(val);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.controller.setSearch(val);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      widget.controller.loadMoreBookings();
    }
  }

  Future<void> _confirmAndReject(BookingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Booking Slot?'),
        content: Text(
          'Are you sure you want to cancel the booking for ${item.displayName} (${item.grainType})?',
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
        bookingId: item.id,
        newStatus: 'cancelled',
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking for ${item.displayName} cancelled.'),
              backgroundColor: AppColors.text,
            ),
          );
        } else if (widget.controller.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.controller.errorMessage!),
              backgroundColor: AppColors.bad,
            ),
          );
        }
      }
    }
  }

  Future<void> _approveBooking(BookingItem item) async {
    final success = await widget.controller.updateStatus(
      bookingId: item.id,
      newStatus: 'confirmed',
    );
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking for ${item.displayName} confirmed.'),
            backgroundColor: AppColors.canopyDeep,
          ),
        );
      } else if (widget.controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.controller.errorMessage!),
            backgroundColor: AppColors.bad,
          ),
        );
      }
    }
  }

  void _openDetail(BookingItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingDetailSheet(
        item: item,
        isActionInFlight: widget.controller.actionInFlightId == item.id,
        onApprove: () {
          Navigator.of(ctx).pop();
          _approveBooking(item);
        },
        onReject: () {
          Navigator.of(ctx).pop();
          _confirmAndReject(item);
        },
        onInspect: item.isDelivered
            ? () {
                Navigator.of(ctx).pop();
                _inspectBooking(item);
              }
            : null,
      ),
    );
  }

  Future<void> _inspectBooking(BookingItem item) async {
    final recorded = await InspectBookingSheet.show(
      context: context,
      isSubmitting: widget.controller.actionInFlightId == item.id,
      errorMessage: () => widget.controller.errorMessage,
      onSubmit: ({
        required goodQuantityKg,
        required badQuantityKg,
        rejectionReason,
        notes,
      }) {
        return widget.controller.inspectBooking(
          bookingId: item.id,
          goodQuantityKg: goodQuantityKg,
          badQuantityKg: badQuantityKg,
          rejectionReason: rejectionReason,
          notes: notes,
        );
      },
    );
    if (recorded == true && mounted) {
      // Reload so the backend's post-inspection status is reflected.
      widget.controller.refreshBookings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inspection recorded for ${item.displayName}.'),
          backgroundColor: AppColors.canopyDeep,
        ),
      );
    }
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
                // Top Header matching HTML #screen-booking-slot
                _buildHeader(),
                const SizedBox(height: 8),

                // 7-day Date Selector Strip matching HTML #date-strip
                DateSelectorStrip(
                  selectedDate: widget.controller.selectedDate,
                  onDateSelected: widget.controller.setDateFilter,
                ),
                const SizedBox(height: 12),

                // Search Bar
                _buildSearchBar(),
                const SizedBox(height: 12),

                // Filter Chip Row
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
                  'Farmer delivery bookings',
                  style: AppTypography.eyebrow(color: AppColors.textMuted),
                ),
                Text(
                  'Booking Slots',
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
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        onSubmitted: (val) {
          _searchDebounce?.cancel();
          widget.controller.setSearch(val);
        },
        decoration: InputDecoration(
          hintText: 'Search by farmer or grain...',
          hintStyle: AppTypography.bodySmall(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                  onPressed: () {
                    _searchDebounce?.cancel();
                    _searchController.clear();
                    setState(() {});
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
      ('confirmed', 'Confirmed'),
      ('delivered', 'Delivered'),
      ('inspected', 'Inspected'),
      ('completed', 'Completed'),
      ('cancelled', 'Cancelled'),
    ];

    final active = widget.controller.activeFilter;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < filters.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Builder(
                  builder: (context) {
                    final f = filters[i];
                    final isSelected = active == f.$1;
                    final totalCount = widget.controller.countForFilter(f.$1);

                    return FilterChip(
                      label: Text(
                        totalCount != null ? '${f.$2} ($totalCount)' : f.$2,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.text,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 11.5,
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
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      labelPadding: EdgeInsets.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.controller.isLoading || widget.controller.status == BookingViewStatus.initial) {
      return const DashboardLoadingView();
    }

    if (widget.controller.isError) {
      return DashboardErrorView(
        message: widget.controller.errorMessage ?? 'Failed to load booking slots',
        onRetry: widget.controller.loadBookings,
      );
    }

    final items = widget.controller.bookings;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'No bookings found',
                style: AppTypography.titleSmall(color: AppColors.text),
              ),
              const SizedBox(height: 4),
              Text(
                widget.controller.selectedDate != null
                    ? 'No bookings scheduled for the selected date.'
                    : 'Farmer delivery bookings will appear here.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.controller.refreshBookings,
      color: AppColors.canopy,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: items.length + (widget.controller.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= items.length) {
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
          return BookingCard(
            item: item,
            isActionInFlight: widget.controller.actionInFlightId == item.id,
            onTap: () => _openDetail(item),
            onApprove: () => _approveBooking(item),
            onReject: () => _confirmAndReject(item),
          );
        },
      ),
    );
  }
}
