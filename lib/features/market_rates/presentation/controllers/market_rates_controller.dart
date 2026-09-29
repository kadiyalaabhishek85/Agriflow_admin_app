import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/user_role.dart';
import '../../../../core/network/error_sanitizer.dart';
import '../../domain/entities/market_rate_group.dart';
import '../../domain/entities/market_rate_item.dart';
import '../../domain/exceptions/market_rates_exception.dart';
import '../../domain/repositories/market_rates_repository.dart';

/// Outcome of a Set Rate submission.
/// `failed > 0` means the operation did NOT fully succeed — the caller must
/// never present a full-success message when `failed > 0`.
typedef SetRatesResult = ({
  int succeeded,
  int failed,
  String? errorMessage,
});

/// State management controller for the Market Rates / Mandi Price Board.
class MarketRatesController extends ChangeNotifier {
  final MarketRatesRepository repository;
  final String accessToken;
  final UserRole role;

  MarketRatesController({
    required this.repository,
    required this.accessToken,
    required this.role,
  });

  List<MarketRateItem> _rates = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _searchQuery = '';
  DateTime? _updatedAt;

  /// Monotonic request generation — a stale response is discarded instead of
  /// overwriting a newer load (same supersede pattern as Billing).
  int _requestGeneration = 0;

  List<MarketRateItem> get rates => List.unmodifiable(_rates);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  DateTime? get updatedAt => _updatedAt;

  /// RBAC: Admin + Super Admin may create rates; Manager is read-only.
  /// (UserRole.canEditMarketRates — AGENTS.md §3 / pre-m8 matrix L185.)
  bool get canSetRate => role.canEditMarketRates;

  /// Grouped + filtered view for the board (client-side search).
  List<MarketRateGroup> get groups =>
      MarketRateGroup.groupRates(_rates, query: _searchQuery);

  /// `Updated 14:35` label for the header, null before first successful load.
  String? get updatedLabel {
    final at = _updatedAt;
    if (at == null) return null;
    return 'Updated ${DateFormat('HH:mm').format(at)}';
  }

  /// Loads the rate board. Always supersedes in-flight loads.
  Future<void> loadRates({bool refresh = false}) async {
    final generation = ++_requestGeneration;

    if (refresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await repository.getRates(accessToken: accessToken);

      if (generation != _requestGeneration) return;

      _rates = items;
      _errorMessage = null;
      _updatedAt = DateTime.now();
    } on MarketRatesException catch (e) {
      if (generation != _requestGeneration) return;
      _errorMessage = e.message;
    } catch (e) {
      if (generation != _requestGeneration) return;
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Loading market rates');
    } finally {
      if (generation == _requestGeneration) {
        _isLoading = false;
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  /// Pull-to-refresh.
  Future<void> refreshRates() => loadRates(refresh: true);

  /// Client-side crop filter (backend has no search parameter; the dataset
  /// is small). Case-insensitive; clearing restores all groups.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() => setSearchQuery('');

  /// Sets grades for one crop — one `POST /api/v1/market-rates` per filled
  /// grade (no bulk endpoint exists). Empty grades are never submitted.
  ///
  /// Partial failures are reported accurately: `failed > 0` with the first
  /// error message, and the board is always reloaded from the backend so the
  /// UI reflects whatever actually persisted.
  Future<SetRatesResult> setRates({
    required String cropType,
    required Map<String, double> prices,
  }) async {
    if (!canSetRate) {
      return (
        succeeded: 0,
        failed: 0,
        errorMessage: ErrorSanitizer.permissionDeniedMessage,
      );
    }

    final entries = [
      for (final grade in MarketRateGroup.gradeOrder)
        if (prices[grade] != null) MapEntry(grade, prices[grade]!),
    ];

    if (entries.isEmpty || cropType.trim().isEmpty) {
      return (
        succeeded: 0,
        failed: 0,
        errorMessage: entries.isEmpty
            ? 'Enter at least one grade price.'
            : 'Select a crop type.',
      );
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    var succeeded = 0;
    var failed = 0;
    String? firstError;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (final entry in entries) {
      try {
        await repository.setRate(
          accessToken: accessToken,
          cropType: cropType.trim(),
          grade: entry.key,
          pricePerKg: entry.value,
          effectiveDate: today,
        );
        succeeded++;
      } on MarketRatesException catch (e) {
        failed++;
        firstError ??= e.message;
      } catch (e) {
        failed++;
        firstError ??= ErrorSanitizer.sanitize(e, defaultAction: 'Setting rate');
      }
    }

    // Always reload from backend so the board shows what really persisted.
    await loadRates(refresh: true);

    _isSubmitting = false;
    notifyListeners();

    return (
      succeeded: succeeded,
      failed: failed,
      errorMessage: failed == 0 ? null : firstError,
    );
  }
}
