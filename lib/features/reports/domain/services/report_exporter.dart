import 'package:flutter/foundation.dart' show immutable;

import '../entities/monthly_report.dart';

enum ReportExportFormat { pdf, csv }

@immutable
class ReportExportResult {
  final bool success;
  final String message;
  final String? location;

  const ReportExportResult({
    required this.success,
    required this.message,
    this.location,
  });
}

abstract class ReportMessages {
  static const String pdfExportSuccess = 'PDF report downloaded';
  static const String csvExportSuccess = 'CSV report downloaded';
  static const String cancelled = 'Download cancelled.';
  static const String buildFailure = 'Could not generate report file.';
  static const String permissionDenied = 'Storage permission denied.';
  static const String saveFailure = 'Unable to save report file.';
}

abstract class ReportExporter {
  Future<ReportExportResult> export({
    required MonthlyReport report,
    required String monthLabel,
    required ReportExportFormat format,
  });
}
