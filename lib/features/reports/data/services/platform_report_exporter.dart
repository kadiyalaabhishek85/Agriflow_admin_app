import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../../../seed_purchase/domain/services/seed_invoice_web_saver.dart';
import '../../domain/entities/monthly_report.dart';
import '../../domain/report_export/report_export_builder.dart';
import '../../domain/services/report_exporter.dart';

typedef ReportPdfBuilderFn = Future<Uint8List> Function(
  MonthlyReport report,
  String monthLabel,
  Uint8List fontBytes,
);
typedef ReportCsvBuilderFn = Uint8List Function(
  MonthlyReport report,
  String monthLabel,
);
typedef ReportFileSaverFn = Future<String?> Function(
  Uint8List bytes,
  String fileName,
  String mimeType,
);
typedef ReportFontLoaderFn = Future<Uint8List> Function();

/// Cross-platform (Web + Android) exporter for Monthly Reports (PDF & CSV).
class PlatformReportExporter implements ReportExporter {
  final ReportPdfBuilderFn buildPdf;
  final ReportCsvBuilderFn buildCsv;
  final ReportFileSaverFn saveFile;
  final ReportFontLoaderFn loadFont;

  PlatformReportExporter({
    ReportPdfBuilderFn? buildPdf,
    ReportCsvBuilderFn? buildCsv,
    ReportFileSaverFn? saveFile,
    ReportFontLoaderFn? loadFont,
  })  : buildPdf = buildPdf ?? _defaultBuildPdf,
        buildCsv = buildCsv ?? buildMonthlyReportCsv,
        saveFile = saveFile ?? _defaultSaveFile,
        loadFont = loadFont ?? _loadFontFromBundle;

  @override
  Future<ReportExportResult> export({
    required MonthlyReport report,
    required String monthLabel,
    required ReportExportFormat format,
  }) async {
    final safeMonth = report.month.replaceAll(RegExp(r'[^0-9A-Za-z_-]'), '_');
    final isPdf = format == ReportExportFormat.pdf;
    final fileName = isPdf
        ? 'AgriFlow_Report_$safeMonth.pdf'
        : 'AgriFlow_Report_$safeMonth.csv';
    final mimeType = isPdf ? 'application/pdf' : 'text/csv';

    final Uint8List bytes;
    try {
      if (isPdf) {
        final fontBytes = await loadFont();
        bytes = await buildPdf(report, monthLabel, fontBytes);
      } else {
        bytes = buildCsv(report, monthLabel);
      }
      if (bytes.isEmpty) {
        return const ReportExportResult(
          success: false,
          message: ReportMessages.buildFailure,
        );
      }
    } catch (_) {
      return const ReportExportResult(
        success: false,
        message: ReportMessages.buildFailure,
      );
    }

    try {
      final location = await saveFile(bytes, fileName, mimeType);
      if (location == null) {
        return const ReportExportResult(
          success: false,
          message: ReportMessages.cancelled,
        );
      }
      return ReportExportResult(
        success: true,
        message: isPdf
            ? ReportMessages.pdfExportSuccess
            : ReportMessages.csvExportSuccess,
        location: location,
      );
    } on PlatformException catch (e) {
      if (e.code.toLowerCase().contains('permission')) {
        return const ReportExportResult(
          success: false,
          message: ReportMessages.permissionDenied,
        );
      }
      return const ReportExportResult(
        success: false,
        message: ReportMessages.saveFailure,
      );
    } catch (_) {
      return const ReportExportResult(
        success: false,
        message: ReportMessages.saveFailure,
      );
    }
  }

  static Future<Uint8List> _defaultBuildPdf(
    MonthlyReport report,
    String monthLabel,
    Uint8List fontBytes,
  ) {
    return buildMonthlyReportPdf(report, monthLabel, fontBytes: fontBytes);
  }

  static Future<String?> _defaultSaveFile(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) {
    if (kIsWeb) {
      return saveInvoiceBytesOnWeb(bytes, fileName, mimeType: mimeType);
    }
    return FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: bytes,
        fileName: fileName,
        mimeTypesFilter: <String>[mimeType],
      ),
    );
  }

  static Future<Uint8List> _loadFontFromBundle() async {
    final data = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
