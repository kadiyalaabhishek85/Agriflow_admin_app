import 'package:agriflow_admin/core/utils/app_initials.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Domain entity representing a financial transaction/invoice from the AgriFlow FastAPI backend.
/// Strictly models `TransactionPublic` schema from `/api/v1/transactions`.
@immutable
class BillingTransactionItem {
  final String id;
  final String referenceType; // 'seed_purchase', 'grain_sale', 'billing', 'other'
  final String? referenceId;
  final String farmerId;
  final double amount;
  final String direction; // 'credit', 'debit'
  final String status; // 'pending', 'completed', 'failed'
  final String? description;
  final String? invoiceNumber;
  final DateTime createdAt;

  // Enriched fields from lookup catalog
  final String? enrichedFarmerName;
  final String? enrichedFarmerPhone;
  final String? enrichedFarmerVillage;

  const BillingTransactionItem({
    required this.id,
    required this.referenceType,
    this.referenceId,
    required this.farmerId,
    required this.amount,
    required this.direction,
    required this.status,
    this.description,
    this.invoiceNumber,
    required this.createdAt,
    this.enrichedFarmerName,
    this.enrichedFarmerPhone,
    this.enrichedFarmerVillage,
  });

  factory BillingTransactionItem.fromJson(Map<String, dynamic> json) {
    // Amount can arrive as double, int, num, or string
    double parsedAmount = 0.0;
    final rawAmount = json['amount'];
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      parsedAmount = double.tryParse(rawAmount) ?? 0.0;
    }

    DateTime parsedDate = DateTime.now();
    if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    }

    return BillingTransactionItem(
      id: json['id'] as String? ?? '',
      referenceType: (json['reference_type'] as String? ?? 'other').toLowerCase(),
      referenceId: json['reference_id'] as String?,
      farmerId: json['farmer_id'] as String? ?? '',
      amount: parsedAmount,
      direction: (json['direction'] as String? ?? 'credit').toLowerCase(),
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      description: json['description'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      createdAt: parsedDate,
    );
  }

  BillingTransactionItem copyWith({
    String? id,
    String? referenceType,
    String? referenceId,
    String? farmerId,
    double? amount,
    String? direction,
    String? status,
    String? description,
    String? invoiceNumber,
    DateTime? createdAt,
    String? enrichedFarmerName,
    String? enrichedFarmerPhone,
    String? enrichedFarmerVillage,
  }) {
    return BillingTransactionItem(
      id: id ?? this.id,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      farmerId: farmerId ?? this.farmerId,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      description: description ?? this.description,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      createdAt: createdAt ?? this.createdAt,
      enrichedFarmerName: enrichedFarmerName ?? this.enrichedFarmerName,
      enrichedFarmerPhone: enrichedFarmerPhone ?? this.enrichedFarmerPhone,
      enrichedFarmerVillage: enrichedFarmerVillage ?? this.enrichedFarmerVillage,
    );
  }

  BillingTransactionItem copyWithEnrichment({
    String? farmerName,
    String? farmerPhone,
    String? farmerVillage,
  }) {
    return BillingTransactionItem(
      id: id,
      referenceType: referenceType,
      referenceId: referenceId,
      farmerId: farmerId,
      amount: amount,
      direction: direction,
      status: status,
      description: description,
      invoiceNumber: invoiceNumber,
      createdAt: createdAt,
      enrichedFarmerName: farmerName ?? enrichedFarmerName,
      enrichedFarmerPhone: farmerPhone ?? enrichedFarmerPhone,
      enrichedFarmerVillage: farmerVillage ?? enrichedFarmerVillage,
    );
  }

  /// Display farmer name with fallback to short ID
  String get displayFarmerName {
    if (enrichedFarmerName != null && enrichedFarmerName!.trim().isNotEmpty) {
      return enrichedFarmerName!;
    }
    if (farmerId.isEmpty) {
      return 'AgriFlow System';
    }
    final shortId = farmerId.length > 8 ? farmerId.substring(0, 8) : farmerId;
    return 'Farmer #$shortId';
  }

  /// Farmer initials for avatar
  String get farmerInitials => AppInitials.of(enrichedFarmerName, fallback: 'TX');

  /// Display invoice number with fallback to transaction ID
  String get displayInvoiceNumber {
    if (invoiceNumber != null && invoiceNumber!.trim().isNotEmpty) {
      return invoiceNumber!;
    }
    final shortId = id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
    return 'INV-$shortId';
  }

  /// Formatted date string
  String get formattedDate {
    return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);
  }

  /// Short date string for lists
  String get shortDate {
    return DateFormat('dd MMM yyyy').format(createdAt);
  }

  /// Display amount formatted in INR with currency symbol
  String get displayAmount {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(amount);
  }

  /// Display friendly name for reference type
  String get displayReferenceType {
    switch (referenceType.toLowerCase()) {
      case 'seed_purchase':
        return 'Seed Purchase';
      case 'grain_sale':
        return 'Grain Sale Payout';
      case 'billing':
        return 'Service Bill';
      default:
        return 'General Transaction';
    }
  }

  bool get isCredit => direction.toLowerCase() == 'credit';
  bool get isDebit => direction.toLowerCase() == 'debit';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillingTransactionItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          amount == other.amount;

  @override
  int get hashCode => id.hashCode ^ status.hashCode ^ amount.hashCode;
}
