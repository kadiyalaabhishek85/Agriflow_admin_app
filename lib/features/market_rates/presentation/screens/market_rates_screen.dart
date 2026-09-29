import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../controllers/market_rates_controller.dart';
import '../widgets/market_rate_card.dart';
import '../widgets/set_rate_sheet.dart';

/// Market Rates / Mandi Price Board matching approved HTML `#screen-market-rates`.
///
/// View, client-side search, pull-to-refresh, and (Admin/Super Admin only)
/// Set Rate creation against the verified FastAPI contract.
class MarketRatesScreen extends StatefulWidget {
  final MarketRatesController controller;
  final VoidCallback onBack;

  const MarketRatesScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  @override
  State<MarketRatesScreen> createState() => _MarketRatesScreenState();
}

class _MarketRatesScreenState extends State<MarketRatesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.rates.isEmpty && !widget.controller.isLoading) {
        widget.controller.loadRates();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _openSetRateSheet() async {
    final result = await SetRateSheet.show(
      context,
      controller: widget.controller,
    );
    if (!mounted || result == null) return;

    final messenger = ScaffoldMessenger.of(context);
    if (result.failed == 0 && result.succeeded > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.succeeded == 1
                      ? 'Market rate set successfully'
                      : '${result.succeeded} market rates set successfully',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.good,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (result.succeeded > 0 && result.failed > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${result.succeeded} of ${result.succeeded + result.failed} '
            'grades. ${result.errorMessage ?? 'Some grades failed.'}',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.warn,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'Unable to set market rates.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.bad,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshRates,
          color: AppColors.canopy,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.text,
                            ),
                            onPressed: widget.onBack,
                            splashRadius: 24,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live mandi prices',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Market Rates',
                                  style: GoogleFonts.manrope(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (controller.canSetRate)
                            ElevatedButton.icon(
                              key: const ValueKey('market-rates-set-rate'),
                              onPressed: controller.isSubmitting
                                  ? null
                                  : _openSetRateSheet,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                'Set Rate',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.canopy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                          else
                            const SizedBox(width: 38),
                        ],
                      ),
                      if (controller.updatedLabel != null) ...[
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            controller.updatedLabel!,
                            key: const ValueKey('market-rates-updated-at'),
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Client-side crop search (backend has no search param).
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: TextField(
                          key: const ValueKey('market-rates-search'),
                          controller: _searchController,
                          onChanged: controller.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Search by crop type...',
                            hintStyle: GoogleFonts.manrope(
                              fontSize: 13,
                              color: AppColors.textFaint,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      controller.clearSearch();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (controller.isLoading && controller.rates.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: AppLoadingView(message: 'Loading market rates...'),
                  ),
                )
              else if (controller.errorMessage != null &&
                  controller.rates.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: AppErrorView(
                      message: controller.errorMessage!,
                      onRetry: controller.loadRates,
                    ),
                  ),
                )
              else if (controller.rates.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: EmptyStateView(
                      title: 'No Market Rates Configured',
                      description:
                          'Rates set by Admins will appear here grouped by crop and grade.',
                      icon: Icon(
                        Icons.trending_up_rounded,
                        size: 28,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ),
                )
              else if (controller.groups.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: EmptyStateView(
                      title: 'No Matching Crops',
                      description:
                          'No crops match \u201c${controller.searchQuery}\u201d. Clear the search to see all rates.',
                      icon: Icon(
                        Icons.search_off_rounded,
                        size: 28,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MarketRateCard(
                          group: controller.groups[index],
                        ),
                      ),
                      childCount: controller.groups.length,
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
