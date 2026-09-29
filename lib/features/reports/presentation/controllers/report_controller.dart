import 'package:flutter/foundation.dart';

import '../../../../core/network/error_sanitizer.dart';
import '../../domain/entities/monthly_report.dart';
import '../../domain/entities/reports_exception.dart';
import '../../domain/repositories/report_repository.dart';

/// State management controller for the Monthly Reports module (M7-2).
class ReportController extends ChangeNotifier {
  final ReportRepository repository;
  final String accessToken;

  ReportController({
    required this.repository,
    required this.accessToken,
  });

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final DateTime _now = DateTime.now();
  MonthlyReport? _report;
  bool _isLoading = false;
  String? _errorMessage;
  late String _month = _formatMonth(_now.year, _now.month);

  static String _formatMonth(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  MonthlyReport? get report => _report;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get month => _month;

  /// Human-readable month label, e.g. `Sep 2026`.
  String get monthLabel {
    final parts = _month.split('-');
    final year = int.tryParse(parts[0]) ?? 0;
    final monthIndex = (int.tryParse(parts[1]) ?? 1) - 1;
    if (monthIndex < 0 || monthIndex > 11) return _month;
    return '${_monthNames[monthIndex]} $year';
  }

  /// Loads the currently selected month (first render or explicit refresh).
  Future<void> loadReport({bool refresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _report = await repository.getMonthlyReport(
        accessToken: accessToken,
        month: _month,
      );
    } on ReportsException catch (e) {
      _errorMessage = e.message;
      if (refresh) _report = null;
    } catch (e) {
      _errorMessage =
          ErrorSanitizer.sanitize(e, defaultAction: 'Loading report');
      if (refresh) _report = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Moves one month back and reloads the report for that month.
  Future<void> goToPreviousMonth() => _shiftMonth(-1);

  /// Moves one month forward and reloads the report for that month.
  Future<void> goToNextMonth() => _shiftMonth(1);

  Future<void> _shiftMonth(int delta) async {
    final parts = _month.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final shifted = DateTime(year, month + delta);
    _month = _formatMonth(shifted.year, shifted.month);
    await loadReport();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
