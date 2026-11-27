import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../domain/entities/farmer_item.dart';
import '../controllers/farmer_controller.dart';
import '../widgets/add_farmer_sheet.dart';
import '../widgets/bank_change_requests_sheet.dart';
import '../widgets/edit_farmer_profile_sheet.dart';
import '../widgets/farmer_card.dart';
import '../widgets/farmer_detail_sheet.dart';

/// Screen representing the All Farmers module for both Admin and Manager roles.
/// Strictly implements the approved HTML designs (`AdminMobile UIUX.html` & `Manager Dashboard UIUX.html`).
class FarmerScreen extends StatefulWidget {
  final FarmerController controller;
  final VoidCallback onBack;
  final bool isManagerRole;
  final void Function(String phone)? onCallFarmer;

  const FarmerScreen({
    super.key,
    required this.controller,
    required this.onBack,
    this.isManagerRole = false,
    this.onCallFarmer,
  });

  @override
  State<FarmerScreen> createState() => _FarmerScreenState();
}

class _FarmerScreenState extends State<FarmerScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.farmers.isEmpty) {
        widget.controller.loadFarmers();
      }
      if (!widget.isManagerRole) {
        widget.controller.loadBankChangeRequests();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
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

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      widget.controller.loadMoreFarmers();
    }
  }

  void _openDetailSheet(FarmerItem farmer) {
    widget.controller.selectFarmer(farmer);
    // Exercise GET /farmers/{farmer_id} so full profile fields load (flutter-03 rec 7)
    widget.controller.loadFarmerDetail(farmer.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final current = widget.controller.selectedFarmer ?? farmer;
            return FarmerDetailSheet(
              farmer: current,
              isAdmin: !widget.isManagerRole,
              isSubmitting: widget.controller.isSubmitting,
              onCallFarmer: widget.onCallFarmer,
              onApprove: () async {
                final nav = Navigator.of(sheetContext);
                final messenger = ScaffoldMessenger.of(context);
                final ok = await widget.controller.approveFarmer(current.id);
                if (!mounted) return;
                if (ok) {
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Farmer ${current.name} approved successfully.'),
                      backgroundColor: AppColors.good,
                    ),
                  );
                } else if (widget.controller.errorMessage != null) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(widget.controller.errorMessage!),
                      backgroundColor: AppColors.bad,
                    ),
                  );
                }
              },
              onReject: () async {
                final nav = Navigator.of(sheetContext);
                final messenger = ScaffoldMessenger.of(context);
                final ok = await widget.controller.rejectFarmer(current.id);
                if (!mounted) return;
                if (ok) {
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Farmer ${current.name} rejected.'),
                      backgroundColor: AppColors.bad,
                    ),
                  );
                } else if (widget.controller.errorMessage != null) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(widget.controller.errorMessage!),
                      backgroundColor: AppColors.bad,
                    ),
                  );
                }
              },
              onSuspend: !widget.isManagerRole
                  ? () async {
                      final nav = Navigator.of(sheetContext);
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await widget.controller.suspendFarmer(current.id);
                      if (!mounted) return;
                      if (ok) {
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Farmer ${current.name} account suspended.'),
                            backgroundColor: AppColors.warn,
                          ),
                        );
                      } else if (widget.controller.errorMessage != null) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(widget.controller.errorMessage!),
                            backgroundColor: AppColors.bad,
                          ),
                        );
                      }
                    }
                  : null,
              onEdit: !widget.isManagerRole
                  ? () => _openEditSheet(widget.controller.selectedFarmer ?? current)
                  : null,
            );
          },
        );
      },
    );
  }

  void _openAddFarmerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AddFarmerSheet(
          onSubmit: ({
            required String name,
            required String phone,
            required String password,
            String? email,
            String? address,
            double? acresOfLand,
            String? cropAddress,
          }) async {
            final created = await widget.controller.createFarmer(
              name: name,
              phone: phone,
              password: password,
              email: email,
              address: address,
              acresOfLand: acresOfLand,
              cropAddress: cropAddress,
            );

            if (created != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Farmer ${created.name} registered successfully.'),
                  backgroundColor: AppColors.good,
                ),
              );
              return true;
            }
            return false;
          },
          errorMessage: () => widget.controller.errorMessage,
        );
      },
    );
  }

  /// FEAT-04 — partial farmer profile edit via PATCH /farmers/{farmer_id}
  Future<void> _openEditSheet(FarmerItem farmer) async {
    final updated = await EditFarmerProfileSheet.show(
      context: context,
      farmer: farmer,
      isSubmitting: widget.controller.isSubmitting,
      onSubmit: ({
        required String name,
        required String phone,
        String? email,
        String? address,
        double? acresOfLand,
        String? soilType,
        String? irrigationType,
        String? primaryCrop,
        String? secondaryCrop,
      }) {
        return widget.controller.updateFarmerProfile(
          farmerId: farmer.id,
          name: name,
          phone: phone,
          email: email,
          address: address,
          acresOfLand: acresOfLand,
          soilType: soilType,
          irrigationType: irrigationType,
          primaryCrop: primaryCrop,
          secondaryCrop: secondaryCrop,
        );
      },
      errorMessage: () => widget.controller.errorMessage,
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile for ${farmer.name} updated successfully.'),
          backgroundColor: AppColors.good,
        ),
      );
    }
  }

  void _openBankRequestsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return BankChangeRequestsSheet(
              requests: widget.controller.bankRequests,
              isLoading: widget.controller.isLoadingBankRequests,
              errorMessage: widget.controller.bankRequestsError,
              hasMore: widget.controller.bankRequestsHasMore,
              isLoadingMore: widget.controller.isLoadingMoreBankRequests,
              onLoadMore: () => widget.controller.loadMoreBankRequests(),
              onRefresh: () => widget.controller.loadBankChangeRequests(refresh: true),
              onReview: ({
                required String requestId,
                required bool approve,
                String? adminNotes,
              }) async {
                return await widget.controller.reviewBankChangeRequest(
                  requestId: requestId,
                  approve: approve,
                  adminNotes: adminNotes,
                );
              },
            );
          },
        );
      },
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar
                _buildHeader(ctrl),

                // Summary Counters
                _buildSummaryCounters(ctrl),

                // Search Bar
                _buildSearchBar(ctrl),

                // Status Filter Chips
                _buildFilterChips(ctrl),

                // Error Banner if list has items but last action errored
                if (ctrl.errorMessage != null && ctrl.farmers.isNotEmpty) ...[
                  _buildErrorBanner(ctrl.errorMessage!),
                ],

                // Farmers List
                Expanded(
                  child: _buildFarmersList(ctrl),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(FarmerController ctrl) {
    final eyebrow = widget.isManagerRole ? 'FARMER DIRECTORY' : 'GLOBAL FARMER DIRECTORY';

    return Padding(
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textFaint,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'All Farmers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),

          // Admin Bank Requests Action Button
          if (!widget.isManagerRole) ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                SquircleIconButton(
                  icon: const Icon(
                    Icons.account_balance_outlined,
                    size: 18,
                    color: AppColors.adminNavy,
                  ),
                  size: 38,
                  onTap: _openBankRequestsSheet,
                ),
                if (ctrl.pendingBankRequestsCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.alert,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${ctrl.pendingBankRequestsCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],

          // Add Farmer Action Button
          SquircleIconButton(
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 18,
              color: AppColors.canopy,
            ),
            size: 38,
            onTap: _openAddFarmerSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCounters(FarmerController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _buildCounterCard(
              label: 'ACTIVE',
              count: ctrl.activeCount,
              color: AppColors.good,
              bgColor: const Color(0xFFE5F6EA),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCounterCard(
              label: 'PENDING',
              count: ctrl.pendingCount,
              color: AppColors.warn,
              bgColor: AppColors.warnBg.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterCard({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              label == 'ACTIVE' ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
              size: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(FarmerController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          onSubmitted: (val) {
            _searchDebounce?.cancel();
            ctrl.setSearchQuery(val);
          },
          decoration: InputDecoration(
            hintText: 'Search by name or phone...',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textFaint,
            ),
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textFaint),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textFaint),
                    onPressed: () {
                      _searchDebounce?.cancel();
                      _searchController.clear();
                      setState(() {});
                      ctrl.setSearchQuery('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          style: const TextStyle(fontSize: 13.5, color: AppColors.text),
        ),
      ),
    );
  }

  Widget _buildFilterChips(FarmerController ctrl) {
    final filters = <String>[
      'all',
      'active',
      'pending',
      'rejected',
      if (!widget.isManagerRole) 'suspended',
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = ctrl.currentFilter == filter;
          final title = filter == 'all' ? 'All' : filter[0].toUpperCase() + filter.substring(1);

          return ChoiceChip(
            label: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => ctrl.setFilter(filter),
            selectedColor: AppColors.forest,
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected ? AppColors.forest : AppColors.line,
              ),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          );
        },
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.badBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.badBg),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.bad),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11.5, color: AppColors.bad, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmersList(FarmerController ctrl) {
    if (ctrl.isLoading && ctrl.farmers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.canopy),
      );
    }

    if (ctrl.errorMessage != null && ctrl.farmers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.bad),
              const SizedBox(height: 12),
              Text(
                ctrl.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ctrl.loadFarmers(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.canopy,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (ctrl.farmers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textFaint),
              SizedBox(height: 12),
              Text(
                'No farmers found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Try a different name or phone number.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ctrl.refreshFarmers(),
      color: AppColors.canopy,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        itemCount: ctrl.farmers.length + (ctrl.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == ctrl.farmers.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.canopy),
                ),
              ),
            );
          }

          final farmer = ctrl.farmers[index];
          return FarmerCard(
            farmer: farmer,
            onTap: () => _openDetailSheet(farmer),
          );
        },
      ),
    );
  }
}
