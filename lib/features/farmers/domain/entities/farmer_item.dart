import 'package:agriflow_admin/core/utils/app_initials.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'farmer_profile_item.dart';

/// Domain entity representing a Farmer from FastAPI backend.
/// Strictly models `FarmerAdminView` from `/api/v1/farmers`.
@immutable
class FarmerItem {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String status; // 'pending', 'active', 'rejected', 'suspended'
  final DateTime createdAt;
  final FarmerProfileItem? profile;

  const FarmerItem({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.status,
    required this.createdAt,
    this.profile,
  });

  factory FarmerItem.fromJson(Map<String, dynamic> json) {
    FarmerProfileItem? profile;
    if (json['farmer_profile'] != null && json['farmer_profile'] is Map<String, dynamic>) {
      profile = FarmerProfileItem.fromJson(json['farmer_profile'] as Map<String, dynamic>);
    }

    return FarmerItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      profile: profile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'farmer_profile': profile?.toJson(),
    };
  }

  FarmerItem copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? status,
    DateTime? createdAt,
    FarmerProfileItem? profile,
  }) {
    return FarmerItem(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      profile: profile ?? this.profile,
    );
  }

  /// Calculates avatar initials (e.g. "Ramulu Naik" -> "RN", "Suresh" -> "S")
  String get initials => AppInitials.of(name);

  /// Returns land acreage string, fallback to profile or '0'
  String get landAcres => profile?.acresOfLand ?? '0';

  String get landAcresDisplay => '$landAcres acres';

  String get villageOrAddress => profile?.address?.trim() ?? '';

  String get formattedJoinedDate {
    return DateFormat('dd MMM yyyy').format(createdAt);
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isSuspended => status == 'suspended';
}
