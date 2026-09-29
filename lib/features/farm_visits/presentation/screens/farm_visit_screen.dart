import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/farm_visit_item.dart';
import '../controllers/farm_visit_controller.dart';
import '../widgets/complete_visit_dialog.dart';
import '../widgets/farm_visit_card.dart';
import '../widgets/farm_visit_detail_sheet.dart';
import '../widgets/reschedule_visit_dialog.dart';
import '../widgets/schedule_visit_sheet.dart';
import '../../../dashboard/shared/presentation/widgets/dashboard_state_views.dart';

class FarmVisitScreen extends StatefulWidget {
  final FarmVisitController controller;
  final VoidCallback onBack;

  const FarmVisitScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  @override
  State<FarmVisitScreen> createState() => _FarmVisitScreenState();
}

class _FarmVisitScreenState extends State<FarmVisitScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  static const List<({String label, String value})> _filters = [
    (label: 'All', value: 'all'),
    (label: 'Scheduled', value: 'scheduled'),
    (label: 'Pending Review', value: 'pending_review'),
    (label: 'Completed', value: 'completed'),
    (label: 'Cancelled', value: 'cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.status == FarmVisitViewStatus.initial) {
        widget.controller.loadVisits();
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
      widget.controller.loadMoreVisits();
    }
  }

  void _openDetailSheet(FarmVisitItem item) {
    FarmVisitDetailSheet.show(
      context,
      item: item,
      onReschedule: () {
        Navigator.of(context).pop();
        _openRescheduleDialog(item);
      },
      onComplete: () {
        Navigator.of(context).pop();
        _openCompleteDialog(item);
      },
    );
  }

  Future<void> _openRescheduleDialog(FarmVisitItem item) async {
    final success = await RescheduleVisitDialog.show(
      context,
      item: item,
      onConfirm: (newDate) async {
        return await widget.controller.scheduleVisit(
          visitId: item.id,
          scheduledDate: newDate,
        );
      },
      errorMessage: () => widget.controller.errorMessage,
    );

    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visit for ${item.displayFarmerName} rescheduled successfully.'),
          backgroundColor: AppColors.text,
        ),
      );
    } else if (widget.controller.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage!),
          backgroundColor: AppColors.bad,
        ),
      );
    }
  }

  Future<void> _openCompleteDialog(FarmVisitItem item) async {
    final success = await CompleteVisitDialog.show(
      context,
      item: item,
      onUploadPhoto: ({
        required fileBytes,
        required fileName,
        required contentType,
      }) =>
          widget.controller.uploadVisitPhoto(
            fileBytes: fileBytes,
            fileName: fileName,
            contentType: contentType,
          ),
      onConfirm: ({
        required String verifiedAcres,
        required String report,
        String? diagnosis,
        String? recommendation,
      }) async {
        return await widget.controller.completeVisit(
          visitId: item.id,
          verifiedAcres: verifiedAcres,
          report: report,
          diagnosis: diagnosis,
          recommendation: recommendation,
        );
      },
      errorMessage: () => widget.controller.errorMessage,
    );

    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visit for ${item.displayFarmerName} marked as complete.'),
          backgroundColor: AppColors.good,
        ),
      );
    } else if (widget.controller.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage!),
          backgroundColor: AppColors.bad,
        ),
      );
    }
  }

  Future<void> _sendReminders() async {
    final message = await widget.controller.sendVisitReminders();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? widget.controller.errorMessage ?? 'Could not send reminders.',
        ),
        backgroundColor: message != null ? AppColors.good : AppColors.bad,
      ),
    );
  }

  Future<void> _openScheduleSheet() async {
    final created = await ScheduleVisitSheet.show(
      context: context,
      loadCrops: widget.controller.getCropOptions,
      loadStaff: widget.controller.getStaffOptions,
      isSubmitting: widget.controller.isLoading,
      onSubmit: ({
        required String cropId,
        required int visitMonth,
        required String scheduledDate,
        String? staffId,
      }) {
        return widget.controller.createVisit(
          cropId: cropId,
          visitMonth: visitMonth,
          scheduledDate: scheduledDate,
          staffId: staffId,
        );
      },
      errorMessage: () => widget.controller.errorMessage,
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visit scheduled successfully.'),
          backgroundColor: AppColors.good,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Section matching HTML .section-pad
                _buildHeader(context),

                // Search Bar
                _buildSearchBar(),

                // Filter Chips Row
                _buildFilterChips(),

                const SizedBox(height: 12),

                // Main Content Body
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            color: AppColors.text,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Field team schedule',
                  style: AppTypography.eyebrow(color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  'Farm Visits',
                  style: AppTypography.displayMedium(color: AppColors.text).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('farm_visit_reminders_btn'),
            tooltip: 'Send visit reminders',
            onPressed: _sendReminders,
            icon: const Icon(
              Icons.notifications_active_outlined,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
          IconButton(
            key: const Key('farm_visit_create_btn'),
            tooltip: 'Schedule a visit',
            onPressed: _openScheduleSheet,
            icon: const Icon(
              Icons.add_task_outlined,
              size: 20,
              color: AppColors.canopy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: (query) => widget.controller.setSearchQuery(query),
          textInputAction: TextInputAction.search,
          style: AppTypography.bodyMedium(color: AppColors.text),
          decoration: InputDecoration(
            hintText: 'Search by farmer, crop or phone...',
            hintStyle: AppTypography.bodyMedium(color: AppColors.textFaint),
            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      widget.controller.setSearchQuery('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = widget.controller.activeFilter == filter.value;

          return ChoiceChip(
            label: Text(filter.label),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                widget.controller.setFilter(filter.value);
              }
            },
            selectedColor: AppColors.canopy,
            backgroundColor: AppColors.surface,
            labelStyle: AppTypography.bodySmall(
              color: isSelected ? Colors.white : AppColors.text,
            ).copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.canopy : AppColors.line,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (widget.controller.isLoading || widget.controller.status == FarmVisitViewStatus.initial) {
      return const DashboardLoadingView();
    }

    if (widget.controller.isError) {
      return DashboardErrorView(
        message: widget.controller.errorMessage ?? 'Unable to load farm visits.',
        onRetry: widget.controller.loadVisits,
      );
    }

    final visits = widget.controller.visits;

    if (visits.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.controller.refreshVisits,
        color: AppColors.canopy,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    size: 56,
                    color: AppColors.textFaint.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No visits here',
                    style: AppTypography.titleMedium(color: AppColors.text).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No farm visits match this filter.',
                    style: AppTypography.bodySmall(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.controller.refreshVisits,
      color: AppColors.canopy,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: visits.length + (widget.controller.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == visits.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }

          final item = visits[index];
          final isFlight = widget.controller.actionInFlightId == item.id;

          return FarmVisitCard(
            item: item,
            isActionInFlight: isFlight,
            onTap: () => _openDetailSheet(item),
          );
        },
      ),
    );
  }
}
