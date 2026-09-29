import '../receipt/billing_receipt_data.dart';

/// Outcome of a receipt download attempt.
/// [message] is always a fixed, sanitized user-facing string — it never
/// contains raw exception text, stack traces, transport internals, or tokens.
class ReceiptDownloadResult {
  final bool success;
  final String message;

  /// Saved destination (file path / content URI) on success, else null.
  final String? location;

  const ReceiptDownloadResult({
    required this.success,
    required this.message,
    this.location,
  });
}

/// Client-side receipt export contract. The PDF is generated from the
/// already-authorized [BillingReceiptData] — no backend call is involved.
abstract class ReceiptDownloader {
  Future<ReceiptDownloadResult> download({required BillingReceiptData data});
}

/// Fixed, sanitized user-facing messages (single source for the sheet UI).
abstract class ReceiptMessages {
  static const String downloadSuccess = 'Receipt downloaded successfully.';
  static const String pdfFailure =
      'Unable to generate the receipt document. Please try again.';
  static const String saveFailure =
      'Unable to save the receipt file. Please try again.';
  static const String permissionDenied =
      'Storage permission was denied. Please try again.';
  static const String cancelled = 'Download cancelled.';
}
