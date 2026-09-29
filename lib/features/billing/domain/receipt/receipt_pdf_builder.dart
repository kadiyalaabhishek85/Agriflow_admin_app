import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'billing_receipt_data.dart';

/// Builds the downloadable AgriFlow invoice-receipt PDF from verified
/// [BillingReceiptData] only. Pure function: no I/O, no platform calls —
/// unit testable. [fontBytes] must be a Unicode TTF (Noto Sans) because the
/// PDF standard fonts cannot render the ₹ (U+20B9) currency glyph.
Future<Uint8List> buildReceiptPdf(
  BillingReceiptData data, {
  required Uint8List fontBytes,
  bool compress = true,
}) async {
  final font = pw.Font.ttf(ByteData.sublistView(fontBytes));
  final doc = pw.Document(compress: compress);

  pw.Widget row(String label, String value, {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: valueColor ?? PdfColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      build: (context) {
        final children = <pw.Widget>[
          pw.Center(
            child: pw.Text(
              'SRI SIVA SAI SEEDS',
              style: pw.TextStyle(font: font, fontSize: 17, color: PdfColors.grey900),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              'AgriFlow Financial Desk',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'INVOICE RECEIPT',
              style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.indigo800),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey400, thickness: 0.8),
          pw.SizedBox(height: 8),
          row('Invoice Number:', data.invoiceNumber),
          row(
            'Status:',
            data.status,
            valueColor: data.status == 'COMPLETED'
                ? PdfColors.green800
                : data.status == 'FAILED'
                    ? PdfColors.red800
                    : PdfColors.orange800,
          ),
          row('Transaction Type:', data.category),
          row('Date & Time:', data.dateTime),
          row('Farmer / Account:', data.farmerName),
          if (data.phone != null) row('Phone:', data.phone!),
          if (data.referenceId != null) row('Reference ID:', data.referenceId!),
          row('Direction:', data.direction),
          pw.SizedBox(height: 6),
          row('Amount:', data.amount),
          if (data.description != null) ...[
            pw.SizedBox(height: 6),
            row('Description:', data.description!),
          ],
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.grey400, thickness: 0.8),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Generated from AgriFlow transaction record.',
              style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
            ),
          ),
        ];

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: children,
        );
      },
    ),
  );

  return doc.save();
}
