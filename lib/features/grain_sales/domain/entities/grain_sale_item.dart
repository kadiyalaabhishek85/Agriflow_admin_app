import 'package:agriflow_admin/core/utils/app_initials.dart';
import 'package:flutter/foundation.dart';

/// Domain entity representing a Grain Sale from FastAPI backend.
/// Strictly models `GrainSalePublic` schema from `/api/v1/grain-sales`.
@immutable
class GrainSaleItem {
  final String id;
  final String farmerId;
  final String? cropId;
  final String grainType;
  final String grade; // 'A', 'B', 'C'
  final String rawMaterialKg;
  final String goodMaterialKg;
  final String wastageKg;
  final String? pricePerKg;
  final String totalAmount;
  final String status; // 'pending', 'received', 'approved', 'rejected', 'paid'
  final DateTime createdAt;

  final String? bookingSlotId;

  // Enriched fields from lookup catalog
  final String? enrichedFarmerName;
  final String? enrichedFarmerPhone;
  final String? enrichedFarmerVillage;

  const GrainSaleItem({
    required this.id,
    required this.farmerId,
    this.cropId,
    required this.grainType,
    required this.grade,
    required this.rawMaterialKg,
    required this.goodMaterialKg,
    required this.wastageKg,
    this.pricePerKg,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.bookingSlotId,
    this.enrichedFarmerName,
    this.enrichedFarmerPhone,
    this.enrichedFarmerVillage,
  });

  factory GrainSaleItem.fromJson(Map<String, dynamic> json) {
    return GrainSaleItem(
      id: json['id'] as String? ?? '',
      farmerId: json['farmer_id'] as String? ?? '',
      cropId: json['crop_id'] as String?,
      grainType: json['grain_type'] as String? ?? 'Grain',
      grade: json['grade'] as String? ?? 'A',
      rawMaterialKg: (json['raw_material_kg'] ?? '0').toString(),
      goodMaterialKg: (json['good_material_kg'] ?? '0').toString(),
      wastageKg: (json['wastage_kg'] ?? '0').toString(),
      pricePerKg: json['price_per_kg']?.toString(),
      totalAmount: (json['total_amount'] ?? '0').toString(),
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      bookingSlotId: (json['booking_slot_id'] ?? json['booking_id'])?.toString(),
    );
  }

  GrainSaleItem copyWith({
    String? id,
    String? farmerId,
    String? cropId,
    String? grainType,
    String? grade,
    String? rawMaterialKg,
    String? goodMaterialKg,
    String? wastageKg,
    String? pricePerKg,
    String? totalAmount,
    String? status,
    DateTime? createdAt,
    String? bookingSlotId,
    String? enrichedFarmerName,
    String? enrichedFarmerPhone,
    String? enrichedFarmerVillage,
  }) {
    return GrainSaleItem(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      cropId: cropId ?? this.cropId,
      grainType: grainType ?? this.grainType,
      grade: grade ?? this.grade,
      rawMaterialKg: rawMaterialKg ?? this.rawMaterialKg,
      goodMaterialKg: goodMaterialKg ?? this.goodMaterialKg,
      wastageKg: wastageKg ?? this.wastageKg,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      bookingSlotId: bookingSlotId ?? this.bookingSlotId,
      enrichedFarmerName: enrichedFarmerName ?? this.enrichedFarmerName,
      enrichedFarmerPhone: enrichedFarmerPhone ?? this.enrichedFarmerPhone,
      enrichedFarmerVillage: enrichedFarmerVillage ?? this.enrichedFarmerVillage,
    );
  }

  GrainSaleItem copyWithEnrichment({
    String? farmerName,
    String? farmerPhone,
    String? farmerVillage,
  }) {
    return GrainSaleItem(
      id: id,
      farmerId: farmerId,
      cropId: cropId,
      grainType: grainType,
      grade: grade,
      rawMaterialKg: rawMaterialKg,
      goodMaterialKg: goodMaterialKg,
      wastageKg: wastageKg,
      pricePerKg: pricePerKg,
      totalAmount: totalAmount,
      status: status,
      createdAt: createdAt,
      bookingSlotId: bookingSlotId,
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
    final shortId = farmerId.length > 8 ? farmerId.substring(0, 8) : farmerId;
    return 'Farmer #$shortId';
  }

  /// Farmers initials for avatar
  String get farmerInitials => AppInitials.of(enrichedFarmerName);

  /// Convert Raw Material KG to Quintals (1 Quintal = 100 KG)
  String get rawMaterialQuintals {
    final kg = double.tryParse(rawMaterialKg) ?? 0.0;
    final qtl = kg / 100.0;
    return qtl.toStringAsFixed(1);
  }

  /// Convert Good Material KG to Quintals (1 Quintal = 100 KG)
  String get goodMaterialQuintals {
    final kg = double.tryParse(goodMaterialKg) ?? 0.0;
    final qtl = kg / 100.0;
    return qtl.toStringAsFixed(1);
  }

  /// Convert Wastage KG to Quintals (1 Quintal = 100 KG)
  String get wastageQuintals {
    final kg = double.tryParse(wastageKg) ?? 0.0;
    final qtl = kg / 100.0;
    return qtl.toStringAsFixed(1);
  }

  /// Display formatted rate per quintal or per kg
  String get displayRate {
    if (pricePerKg != null && pricePerKg!.isNotEmpty) {
      final pKg = double.tryParse(pricePerKg!) ?? 0.0;
      final pQtl = pKg * 100.0;
      return '₹${pQtl.toStringAsFixed(0)}/qtl';
    }
    final amt = double.tryParse(totalAmount) ?? 0.0;
    final gQtl = (double.tryParse(goodMaterialKg) ?? 0.0) / 100.0;
    if (gQtl > 0 && amt > 0) {
      final rate = amt / gQtl;
      return '₹${rate.toStringAsFixed(0)}/qtl';
    }
    return '₹—/qtl';
  }

  /// Display total payout formatted as INR currency
  String get displayTotalPayout {
    final amt = double.tryParse(totalAmount) ?? 0.0;
    return '₹${amt.toStringAsFixed(0)}';
  }

  /// Display village or location with fallback
  String get displayVillage {
    if (enrichedFarmerVillage != null && enrichedFarmerVillage!.trim().isNotEmpty) {
      return enrichedFarmerVillage!;
    }
    return 'Main Village';
  }

  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isReceived => status.toLowerCase() == 'received';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isPending =>
      status.toLowerCase() == 'pending' ||
      status.toLowerCase() == 'received' ||
      status.toLowerCase() == 'approved';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GrainSaleItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          totalAmount == other.totalAmount;

  @override
  int get hashCode => id.hashCode ^ status.hashCode ^ totalAmount.hashCode;
}
