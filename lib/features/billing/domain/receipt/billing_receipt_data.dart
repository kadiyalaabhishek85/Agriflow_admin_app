import 'package:flutter/foundation.dart';
import '../entities/billing_transaction_item.dart';

/// Single source of truth for receipt content.
///
/// Both the BillingReceiptSheet (UI + Copy Receipt) and the downloaded PDF
/// derive their values from this object, so the on-screen receipt, the
/// clipboard text, and the exported file can never disagree. Every field is
/// copied verbatim from the verified [BillingTransactionItem] — nothing is
/// invented (no GST, tax, line items, payment references, or addresses).
@immutable
class BillingReceiptData {
  final String invoiceNumber;
  final String transactionId;
  final String dateTime;
  final String category;
  final String farmerName;
  final String? phone;
  final String? referenceId;
  final String direction;
  final String amount;
  final String status;
  final String? description;

  const BillingReceiptData({
    required this.invoiceNumber,
    required this.transactionId,
    required this.dateTime,
    required this.category,
    required this.farmerName,
    this.phone,
    this.referenceId,
    required this.direction,
    required this.amount,
    required this.status,
    this.description,
  });

  factory BillingReceiptData.from(BillingTransactionItem item) {
    return BillingReceiptData(
      invoiceNumber: item.displayInvoiceNumber,
      transactionId: item.id,
      dateTime: item.formattedDate,
      category: item.displayReferenceType,
      farmerName: item.displayFarmerName,
      phone: _nonEmpty(item.enrichedFarmerPhone),
      referenceId: _nonEmpty(item.referenceId),
      direction: item.isCredit ? 'Credit (Inflow)' : 'Debit (Outflow)',
      amount: item.displayAmount,
      status: item.status.toUpperCase(),
      description: _nonEmpty(item.description),
    );
  }

  static String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Filesystem-safe suggested file name for the download action.
  /// Example: AgriFlow_Receipt_SP-20260928-94584D0D.pdf
  String get fileName {
    final safe = sanitizeFileNameComponent(invoiceNumber);
    return 'AgriFlow_Receipt_$safe.pdf';
  }

  /// Strips path separators, traversal sequences, reserved and control
  /// characters so an invoice number can never escape the target directory
  /// or produce an invalid file name.
  static String sanitizeFileNameComponent(String value) {
    var safe = value.trim();
    safe = safe.replaceAll(RegExp(r'[^A-Za-z0-9\-]+'), '_');
    safe = safe.replaceAll(RegExp(r'_+'), '_');
    safe = safe.replaceAll(RegExp(r'^_+|_+$'), '');
    return safe.isEmpty ? 'RECEIPT' : safe;
  }

  /// Textual receipt used by the Copy Receipt action.
  /// Same verified values as the on-screen receipt and the PDF.
  String toCopyText() {
    final buffer = StringBuffer()
      ..writeln('AGRIFLOW OFFICIAL INVOICE RECEIPT')
      ..writeln('---------------------------------')
      ..writeln('Invoice No: $invoiceNumber')
      ..writeln('Transaction ID: $transactionId')
      ..writeln('Date: $dateTime')
      ..writeln('Type: $category')
      ..writeln('Direction: $direction')
      ..writeln('Status: $status')
      ..writeln('Amount: $amount')
      ..writeln('Farmer: $farmerName');
    if (phone != null) buffer.writeln('Phone: $phone');
    if (referenceId != null) buffer.writeln('Reference ID: $referenceId');
    if (description != null) buffer.writeln('Description: $description');
    buffer
      ..writeln('---------------------------------')
      ..writeln('Verified AgriFlow Enterprise Record');
    return buffer.toString();
  }
}
