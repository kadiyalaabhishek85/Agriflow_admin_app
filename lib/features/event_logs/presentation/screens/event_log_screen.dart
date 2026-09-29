import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../domain/entities/audit_log_item.dart';
import '../controllers/event_log_controller.dart';

/// Event Logs screen (M7-3): audit trail of admin/manager actions with
/// server-side search and infinite scroll.
class EventLogScreen extends StatefulWidget {
  final EventLogController controller;
  final VoidCallback onBack;

  const EventLogScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  @override
  State<EventLogScreen> createState() => _EventLogScreenState();
}

class _EventLogScreenState extends State<EventLogScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.logs.isEmpty) {
        widget.controller.loadLogs();
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
      widget.controller.loadMoreLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;

        return Scaffold(
          key: const Key('event_log_screen'),
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(ctrl),
                _buildSearchBar(ctrl),
                if (ctrl.errorMessage != null && ctrl.logs.isNotEmpty) ...[
                  _buildErrorBanner(ctrl.errorMessage!),
                ],
                Expanded(
                  child: _buildLogList(ctrl),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(EventLogController ctrl) {
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
                const Text(
                  'AUDIT TRAIL',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textFaint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ctrl.totalRecords > 0
                      ? 'Event Logs · ${ctrl.totalRecords}'
                      : 'Event Logs',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(EventLogController ctrl) {
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
          key: const Key('event_log_search_field'),
          controller: _searchController,
          onChanged: (val) => ctrl.setSearchQuery(val),
          decoration: InputDecoration(
            hintText: 'Search action, entity or details...',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textFaint,
            ),
            prefixIcon: const Icon(Icons.search_rounded,
                size: 20, color: AppColors.textFaint),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    key: const Key('event_log_search_clear_btn'),
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

  Widget _buildLogList(EventLogController ctrl) {
    if (ctrl.isLoading && ctrl.logs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.canopy),
      );
    }

    if (ctrl.errorMessage != null && ctrl.logs.isEmpty) {
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
                key: const Key('event_log_retry_btn'),
                onPressed: () => ctrl.loadLogs(refresh: true),
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

    if (ctrl.logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.history_toggle_off_rounded,
                  size: 48, color: AppColors.textFaint),
              SizedBox(height: 12),
              Text(
                'No events found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Try a different action or entity name.',
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
      onRefresh: () => ctrl.loadLogs(refresh: true),
      color: AppColors.canopy,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        itemCount: ctrl.logs.length + (ctrl.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == ctrl.logs.length) {
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

          return _EventLogTile(log: ctrl.logs[index]);
        },
      ),
    );
  }
}

class _EventLogTile extends StatelessWidget {
  final AuditLogItem log;

  const _EventLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('event_log_tile_${log.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF1FB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded,
                    size: 14, color: AppColors.adminNavy),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  log.action,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                log.createdLabel,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (log.entityType != null && log.entityType!.isNotEmpty)
                _metaChip(Icons.category_outlined, log.entityType!),
              if (log.entityId != null && log.entityId!.isNotEmpty)
                _metaChip(Icons.tag, _shortId(log.entityId!)),
              if (log.userId != null && log.userId!.isNotEmpty)
                _metaChip(Icons.person_outline_rounded, _shortId(log.userId!)),
            ],
          ),
          if (log.details != null && log.details!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              log.details!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  static String _shortId(String id) =>
      id.length > 12 ? '${id.substring(0, 8)}…' : id;
}
