import 'package:flutter/foundation.dart';

/// Domain entity representing a Farmer Profile from FastAPI backend.
/// Strictly models `FarmerProfilePublic` schema from `/api/v1/farmers`.
@immutable
class FarmerProfileItem {
  final String id;
  final String userId;
  final String? address;
  final String acresOfLand;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;
  final String bankStatus; // 'pending', 'approved', 'rejected'
  final String? soilType;
  final String? irrigationType;
  final String? primaryCrop;
  final String? secondaryCrop;

  const FarmerProfileItem({
    required this.id,
    required this.userId,
    this.address,
    required this.acresOfLand,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
    required this.bankStatus,
    this.soilType,
    this.irrigationType,
    this.primaryCrop,
    this.secondaryCrop,
  });

  factory FarmerProfileItem.fromJson(Map<String, dynamic> json) {
    return FarmerProfileItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      address: json['address'] as String?,
      acresOfLand: (json['acres_of_land'] ?? '0').toString(),
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      ifscCode: json['ifsc_code'] as String?,
      upiId: json['upi_id'] as String?,
      bankStatus: (json['bank_status'] as String? ?? 'pending').toLowerCase(),
      soilType: json['soil_type'] as String?,
      irrigationType: json['irrigation_type'] as String?,
      primaryCrop: json['primary_crop'] as String?,
      secondaryCrop: json['secondary_crop'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'address': address,
      'acres_of_land': acresOfLand,
      'bank_name': bankName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'upi_id': upiId,
      'bank_status': bankStatus,
      'soil_type': soilType,
      'irrigation_type': irrigationType,
      'primary_crop': primaryCrop,
      'secondary_crop': secondaryCrop,
    };
  }

  double get acresNumeric {
    return double.tryParse(acresOfLand) ?? 0.0;
  }
}
