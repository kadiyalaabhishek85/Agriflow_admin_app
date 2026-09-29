import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import 'seed_invoice_data.dart';
import 'seed_invoice_pdf_builder.dart';

typedef SeedInvoicePdfBuilderFn = Future<Uint8List> Function(
  SeedInvoiceData data,
  Uint8List fontBytes,
);
typedef SeedInvoiceFileSaverFn = Future<String?> Function(Uint8List bytes, String fileName);
typedef SeedInvoiceFontLoaderFn = Future<Uint8List> Function();

/// Outcome of an invoice download attempt. [message] is always a fixed,
/// sanitized user-facing string — never raw exception text.
class InvoiceDownloadResult {
  final bool success;
  final String message;
  final String? location;

  const InvoiceDownloadResult({
    required this.success,
    required this.message,
    this.location,
  });
}

/// Fixed, sanitized user-facing messages (single source for the sheet UI).
abstract class InvoiceMessages {
  static const String downloadSuccess = 'Invoice downloaded successfully.';
  static const String pdfFailure =
      'Unable to generate the invoice document. Please try again.';
  static const String saveFailure =
      'Unable to save the invoice file. Please try again.';
  static const String permissionDenied =
      'Storage permission was denied. Please try again.';
  static const String cancelled = 'Download cancelled.';
}

/// Client-side seed-purchase invoice export contract. The PDF is generated
/// from the already-loaded [SeedInvoiceData] — no backend call is involved.
abstract class InvoiceDownloader {
  Future<InvoiceDownloadResult> download({required SeedInvoiceData data});
}

/// Production invoice downloader for Android.
///
/// Flow: load Unicode font (needed for the ₹ glyph) → build PDF → save via
/// the Storage Access Framework system picker (`flutter_file_dialog`), which
/// requires **no storage permissions**. All failures map to fixed sanitized
/// messages; raw exceptions never reach the UI.
///
/// Seam-injectable ([buildPdf], [saveFile], [loadFont]) so unit tests never
/// touch a real filesystem or platform channel.
class AndroidInvoiceDownloader implements InvoiceDownloader {
  final SeedInvoicePdfBuilderFn buildPdf;
  final SeedInvoiceFileSaverFn saveFile;
  final SeedInvoiceFontLoaderFn loadFont;

  AndroidInvoiceDownloader({
    SeedInvoicePdfBuilderFn? buildPdf,
    SeedInvoiceFileSaverFn? saveFile,
    SeedInvoiceFontLoaderFn? loadFont,
  })  : buildPdf = buildPdf ?? _defaultBuildPdf,
        saveFile = saveFile ?? _defaultSaveFile,
        loadFont = loadFont ?? _loadFontFromBundle;

  @override
  Future<InvoiceDownloadResult> download({required SeedInvoiceData data}) async {
    final Uint8List pdfBytes;
    try {
      final fontBytes = await loadFont();
      pdfBytes = await buildPdf(data, fontBytes);
      if (pdfBytes.isEmpty) {
        return const InvoiceDownloadResult(
          success: false,
          message: InvoiceMessages.pdfFailure,
        );
      }
    } catch (_) {
      return const InvoiceDownloadResult(
        success: false,
        message: InvoiceMessages.pdfFailure,
      );
    }

    try {
      final location = await saveFile(pdfBytes, data.fileName);
      if (location == null) {
        return const InvoiceDownloadResult(
          success: false,
          message: InvoiceMessages.cancelled,
        );
      }
      return InvoiceDownloadResult(
        success: true,
        message: InvoiceMessages.downloadSuccess,
        location: location,
      );
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('permission')) {
        return const InvoiceDownloadResult(
          success: false,
          message: InvoiceMessages.permissionDenied,
        );
      }
      return const InvoiceDownloadResult(
        success: false,
        message: InvoiceMessages.saveFailure,
      );
    } catch (_) {
      return const InvoiceDownloadResult(
        success: false,
        message: InvoiceMessages.saveFailure,
      );
    }
  }

  static Future<Uint8List> _defaultBuildPdf(
    SeedInvoiceData data,
    Uint8List fontBytes,
  ) {
    return buildSeedInvoicePdf(data, fontBytes: fontBytes);
  }

  static Future<String?> _defaultSaveFile(Uint8List bytes, String fileName) {
    return FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: bytes,
        fileName: fileName,
        mimeTypesFilter: const ['application/pdf'],
      ),
    );
  }

  static Future<Uint8List> _loadFontFromBundle() async {
    final data = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
