import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Models BankChangeRequestPublic from `/api/v1/farmers/bank-change-requests`.
@immutable
class BankChangeRequestItem {
  final String id;
  final String farmerId;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;
  final String status; // 'pending', 'approved', 'rejected'
  final String? adminNotes;
  final DateTime requestedAt;
  final DateTime? reviewedAt;

  // Enriched farmer details for display
  final String? enrichedFarmerName;
  final String? enrichedFarmerPhone;

  const BankChangeRequestItem({
    required this.id,
    required this.farmerId,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
    required this.status,
    this.adminNotes,
    required this.requestedAt,
    this.reviewedAt,
    this.enrichedFarmerName,
    this.enrichedFarmerPhone,
  });

  factory BankChangeRequestItem.fromJson(Map<String, dynamic> json) {
    return BankChangeRequestItem(
      id: json['id'] as String? ?? '',
      farmerId: json['farmer_id'] as String? ?? '',
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      ifscCode: json['ifsc_code'] as String?,
      upiId: json['upi_id'] as String?,
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      adminNotes: json['admin_notes'] as String?,
      requestedAt: json['requested_at'] != null
          ? DateTime.tryParse(json['requested_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
    );
  }

  BankChangeRequestItem copyWithEnrichment({
    String? farmerName,
    String? farmerPhone,
  }) {
    return BankChangeRequestItem(
      id: id,
      farmerId: farmerId,
      bankName: bankName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      upiId: upiId,
      status: status,
      adminNotes: adminNotes,
      requestedAt: requestedAt,
      reviewedAt: reviewedAt,
      enrichedFarmerName: farmerName ?? enrichedFarmerName,
      enrichedFarmerPhone: farmerPhone ?? enrichedFarmerPhone,
    );
  }

  String get displayFarmerName {
    if (enrichedFarmerName != null && enrichedFarmerName!.trim().isNotEmpty) {
      return enrichedFarmerName!;
    }
    if (farmerId.length >= 8) {
      return 'Farmer #${farmerId.substring(0, 8)}';
    }
    return 'Farmer';
  }

  String get formattedRequestedDate {
    return DateFormat('dd MMM yyyy, hh:mm a').format(requestedAt);
  }

  bool get isPending => status == 'pending';
}
