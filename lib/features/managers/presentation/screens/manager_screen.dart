import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../domain/entities/manager_item.dart';
import '../controllers/manager_controller.dart';
import '../widgets/create_manager_sheet.dart';
import '../widgets/manager_card.dart';
import '../widgets/reset_password_sheet.dart';

/// Managers Admin screen (M7-1): list/create managers, status toggle,
/// and password reset. Route is `adminOnly` (Super Admin & Admin only).
class ManagerScreen extends StatefulWidget {
  final ManagerController controller;
  final VoidCallback onBack;

  const ManagerScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.managers.isEmpty) {
        widget.controller.loadManagers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.controller.loadMoreManagers();
    }
  }

  Future<void> _openCreateSheet() async {
    final created = await CreateManagerSheet.show(
      context: context,
      onSubmit: ({
        required String name,
        required String phone,
        required String password,
        String? email,
        String? assignedRegion,
        String? department,
      }) {
        return widget.controller.createManager(
          name: name,
          phone: phone,
          password: password,
          email: email,
          assignedRegion: assignedRegion,
          department: department,
        );
      },
      errorMessage: () => widget.controller.errorMessage,
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manager account created successfully.'),
          backgroundColor: AppColors.good,
        ),
      );
    }
  }

  Future<void> _toggleStatus(ManagerItem manager) async {
    final activating = manager.isSuspended;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(activating ? 'Activate manager' : 'Suspend manager'),
        content: Text(
          activating
              ? 'Activate the account for ${manager.name}?'
              : 'Suspend the account for ${manager.name}? They will no longer be able to sign in.',
        ),
        actions: [
          TextButton(
            key: const Key('manager_status_cancel_btn'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('manager_status_confirm_btn'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(activating ? 'Activate' : 'Suspend'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await widget.controller.setManagerStatus(
      managerId: manager.id,
      status: activating ? 'active' : 'suspended',
    );
    if (!mounted) return;

    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            activating
                ? '${manager.name} activated successfully.'
                : '${manager.name} suspended.',
          ),
          backgroundColor:
              activating ? AppColors.good : AppColors.warn,
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

  Future<void> _resetPassword(ManagerItem manager) async {
    final message = await ResetPasswordSheet.show(
      context: context,
      managerName: manager.name,
      onSubmit: ({required String newPassword}) {
        return widget.controller.resetManagerPassword(
          managerId: manager.id,
          newPassword: newPassword,
        );
      },
      errorMessage: () => widget.controller.errorMessage,
    );

    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isNotEmpty ? message : 'Password reset successfully.',
          ),
          backgroundColor: AppColors.good,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;

        return Scaffold(
          key: const Key('manager_screen'),
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(ctrl),
                _buildSummaryCounters(ctrl),
                _buildSearchBar(ctrl),
                _buildFilterChips(ctrl),
                if (ctrl.errorMessage != null && ctrl.managers.isNotEmpty) ...[
                  _buildErrorBanner(ctrl.errorMessage!),
                ],
                Expanded(
                  child: _buildManagerList(ctrl),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ManagerController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          SquircleIconButton.back(
            onTap: widget.onBack,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MANAGERS ADMIN',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textFaint,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Managers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),

          // Add manager action
          SquircleIconButton(
            key: const Key('manager_create_btn'),
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 18,
              color: AppColors.canopy,
            ),
            size: 38,
            onTap: _openCreateSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCounters(ManagerController ctrl) {
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
              icon: Icons.check_circle_outline_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCounterCard(
              label: 'SUSPENDED',
              count: ctrl.suspendedCount,
              color: AppColors.warn,
              bgColor: AppColors.warnBg.withValues(alpha: 0.5),
              icon: Icons.pause_circle_outline_rounded,
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
    required IconData icon,
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
            child: Icon(icon, size: 16, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ManagerController ctrl) {
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
          key: const Key('manager_search_field'),
          controller: _searchController,
          onChanged: (val) => ctrl.setSearchQuery(val),
          decoration: InputDecoration(
            hintText: 'Search by name or phone...',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textFaint,
            ),
            prefixIcon: const Icon(Icons.search_rounded,
                size: 20, color: AppColors.textFaint),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    key: const Key('manager_search_clear_btn'),
                    icon: const Icon(Icons.clear_rounded,
                        size: 18, color: AppColors.textFaint),
                    onPressed: () {
                      _searchController.clear();
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

  Widget _buildFilterChips(ManagerController ctrl) {
    const filters = <String>['all', 'active', 'suspended'];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = ctrl.statusFilter == filter;
          final title =
              filter == 'all' ? 'All' : filter[0].toUpperCase() + filter.substring(1);

          return ChoiceChip(
            key: Key('manager_chip_$filter'),
            label: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => ctrl.setStatusFilter(filter),
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
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.bad),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.bad,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerList(ManagerController ctrl) {
    if (ctrl.isLoading && ctrl.managers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.canopy),
      );
    }

    if (ctrl.errorMessage != null && ctrl.managers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppColors.bad),
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
                key: const Key('manager_retry_btn'),
                onPressed: () => ctrl.loadManagers(),
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

    if (ctrl.managers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.manage_accounts_outlined,
                  size: 48, color: AppColors.textFaint),
              SizedBox(height: 12),
              Text(
                'No managers found',
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
      onRefresh: () => ctrl.loadManagers(refresh: true),
      color: AppColors.canopy,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        itemCount: ctrl.managers.length + (ctrl.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == ctrl.managers.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.canopy),
                ),
              ),
            );
          }

          final manager = ctrl.managers[index];
          return ManagerCard(
            manager: manager,
            onToggleStatus: () => _toggleStatus(manager),
            onResetPassword: () => _resetPassword(manager),
          );
        },
      ),
    );
  }
}
