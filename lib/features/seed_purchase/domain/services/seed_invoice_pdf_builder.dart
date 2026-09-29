import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'seed_invoice_data.dart';

/// Builds the downloadable seed-purchase invoice PDF from already-loaded
/// [SeedInvoiceData] only. Pure function: no I/O, no platform calls — unit
/// testable. [fontBytes] must be a Unicode TTF (Noto Sans) because the PDF
/// standard fonts cannot render the ₹ (U+20B9) currency glyph.
Future<Uint8List> buildSeedInvoicePdf(
  SeedInvoiceData data, {
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
            width: 130,
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
              'AgriFlow Seed Purchase Invoice',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'INVOICE',
              style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.green800),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey400, thickness: 0.8),
          pw.SizedBox(height: 8),
          row('Invoice Number:', data.invoiceNumber),
          row(
            'Status:',
            data.paymentStatus.toUpperCase(),
            valueColor: data.paymentStatus == 'paid'
                ? PdfColors.green800
                : data.paymentStatus == 'failed'
                    ? PdfColors.red800
                    : PdfColors.orange800,
          ),
          row('Order Date:', data.orderDate),
          row('Farmer:', data.farmerName),
          if (data.farmerPhone.isNotEmpty) row('Phone:', data.farmerPhone),
          pw.SizedBox(height: 6),
          row('Seed Item:', data.seedName),
          if (data.seedVariety.isNotEmpty) row('Variety:', data.seedVariety),
          row('Quantity:', data.quantity),
          row('Price per kg:', data.pricePerKg),
          pw.SizedBox(height: 6),
          row(
            'Grand Total:',
            data.totalAmount,
            valueColor: PdfColors.green800,
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.grey400, thickness: 0.8),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Generated from AgriFlow seed purchase record. No signature required.',
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
