import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../../../seed_purchase/domain/services/seed_invoice_web_saver.dart';
import '../../domain/receipt/billing_receipt_data.dart';
import '../../domain/receipt/receipt_pdf_builder.dart';
import '../../domain/services/receipt_downloader.dart';

typedef ReceiptPdfBuilderFn = Future<Uint8List> Function(
  BillingReceiptData data,
  Uint8List fontBytes,
);
typedef ReceiptFileSaverFn = Future<String?> Function(Uint8List bytes, String fileName);
typedef ReceiptFontLoaderFn = Future<Uint8List> Function();

/// Production receipt downloader for Android.
///
/// Flow: load Unicode font (needed for the ₹ glyph) → build PDF from verified
/// receipt data → save via the Storage Access Framework system picker
/// (`flutter_file_dialog`), which requires **no storage permissions** and no
/// obsolete external-storage access. All failures map to fixed sanitized
/// messages; raw exceptions never reach the UI.
///
/// Seam-injectable ([buildPdf], [saveFile], [loadFont]) so unit tests never
/// touch a real filesystem or platform channel.
class AndroidReceiptDownloader implements ReceiptDownloader {
  final ReceiptPdfBuilderFn buildPdf;
  final ReceiptFileSaverFn saveFile;
  final ReceiptFontLoaderFn loadFont;

  AndroidReceiptDownloader({
    ReceiptPdfBuilderFn? buildPdf,
    ReceiptFileSaverFn? saveFile,
    ReceiptFontLoaderFn? loadFont,
  })  : buildPdf = buildPdf ?? _defaultBuildPdf,
        saveFile = saveFile ?? _defaultSaveFile,
        loadFont = loadFont ?? _loadFontFromBundle;

  @override
  Future<ReceiptDownloadResult> download({required BillingReceiptData data}) async {
    // 1. PDF generation (font load + document build).
    final Uint8List pdfBytes;
    try {
      final fontBytes = await loadFont();
      pdfBytes = await buildPdf(data, fontBytes);
      if (pdfBytes.isEmpty) {
        return const ReceiptDownloadResult(
          success: false,
          message: ReceiptMessages.pdfFailure,
        );
      }
    } catch (_) {
      return const ReceiptDownloadResult(
        success: false,
        message: ReceiptMessages.pdfFailure,
      );
    }

    // 2. Save through the SAF system picker.
    try {
      final location = await saveFile(pdfBytes, data.fileName);
      if (location == null) {
        // User cancelled the save dialog.
        return const ReceiptDownloadResult(
          success: false,
          message: ReceiptMessages.cancelled,
        );
      }
      return ReceiptDownloadResult(
        success: true,
        message: ReceiptMessages.downloadSuccess,
        location: location,
      );
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('permission')) {
        return const ReceiptDownloadResult(
          success: false,
          message: ReceiptMessages.permissionDenied,
        );
      }
      return const ReceiptDownloadResult(
        success: false,
        message: ReceiptMessages.saveFailure,
      );
    } catch (_) {
      return const ReceiptDownloadResult(
        success: false,
        message: ReceiptMessages.saveFailure,
      );
    }
  }

  static Future<Uint8List> _defaultBuildPdf(
    BillingReceiptData data,
    Uint8List fontBytes,
  ) {
    return buildReceiptPdf(data, fontBytes: fontBytes);
  }

  static Future<String?> _defaultSaveFile(Uint8List bytes, String fileName) {
    if (kIsWeb) {
      return saveInvoiceBytesOnWeb(bytes, fileName);
    }
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
