import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../entities/monthly_report.dart';

/// Builds a formatted A4 PDF report for the selected month using verified
/// [MonthlyReport] metrics. [fontBytes] must contain NotoSans TTF so ₹ renders.
Future<Uint8List> buildMonthlyReportPdf(
  MonthlyReport report,
  String monthLabel, {
  required Uint8List fontBytes,
  bool compress = true,
}) async {
  final font = pw.Font.ttf(ByteData.sublistView(fontBytes));
  final doc = pw.Document(compress: compress);

  pw.Widget metricRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: font, fontSize: 13, color: PdfColors.grey900),
          ),
        ],
      ),
    );
  }

  final generatedAt = DateTime.now().toIso8601String().split('T').first;

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(44),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Text(
              'SRI SIVA SAI SEEDS',
              style: pw.TextStyle(font: font, fontSize: 18, color: PdfColors.grey900),
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Center(
            child: pw.Text(
              'AgriFlow Admin Console · Monthly Operations Report',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.grey400, thickness: 0.8),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Period: $monthLabel (${report.month})',
                style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.green900),
              ),
              pw.Text(
                'Generated: $generatedAt',
                style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          metricRow(
            'Seed Purchases',
            MonthlyReport.formatAmount(report.totalSeedPurchasesAmount),
          ),
          pw.SizedBox(height: 8),
          metricRow(
            'Grain Sales',
            MonthlyReport.formatAmount(report.totalGrainSalesAmount),
          ),
          pw.SizedBox(height: 8),
          metricRow('Total Bookings', '${report.totalBookings}'),
          pw.SizedBox(height: 8),
          metricRow('New Farmers', '${report.newFarmers}'),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey400, thickness: 0.8),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Generated from verified AgriFlow live monthly report data.',
              style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}

String _csvCell(String raw) {
  if (raw.contains(',') || raw.contains('"') || raw.contains('\n')) {
    return '"${raw.replaceAll('"', '""')}"';
  }
  return raw;
}

/// Builds a UTF-8 CSV export from the verified [MonthlyReport].
Uint8List buildMonthlyReportCsv(MonthlyReport report, String monthLabel) {
  final buffer = StringBuffer()
    ..writeln(
      'Month,Period Label,Seed Purchases (INR),Grain Sales (INR),Total Bookings,New Farmers',
    )
    ..writeln(
      [
        _csvCell(report.month),
        _csvCell(monthLabel),
        _csvCell(report.totalSeedPurchasesAmount),
        _csvCell(report.totalGrainSalesAmount),
        '${report.totalBookings}',
        '${report.newFarmers}',
      ].join(','),
    );
  return Uint8List.fromList(utf8.encode(buffer.toString()));
}
