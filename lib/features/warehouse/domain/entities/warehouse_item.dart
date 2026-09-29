import 'package:flutter/foundation.dart';

/// Domain entity representing a warehouse facility in AgriFlow.
/// Maps strictly to `WarehousePublic` from the FastAPI backend.
@immutable
class WarehouseItem {
  final String id;
  final String name;
  final String address;
  final String? location;
  final String? contactNumber;
  final double totalCapacityKg;
  final double currentLoadKg;
  final String? managerId;
  final bool isActive;

  const WarehouseItem({
    required this.id,
    required this.name,
    required this.address,
    this.location,
    this.contactNumber,
    required this.totalCapacityKg,
    required this.currentLoadKg,
    this.managerId,
    this.isActive = true,
  });

  /// 1 Quintal (Qtl) = 100 Kilograms (Kg)
  double get totalCapacityQtl => totalCapacityKg / 100.0;
  double get currentLoadQtl => currentLoadKg / 100.0;

  /// Safe calculation of remaining available capacity
  double get availableCapacityKg =>
      (totalCapacityKg - currentLoadKg).clamp(0.0, double.infinity);
  double get availableCapacityQtl => availableCapacityKg / 100.0;

  /// Display string helpers
  String get displayTotalCapacityQtl => totalCapacityQtl.toStringAsFixed(2);
  String get displayCurrentLoadQtl => currentLoadQtl.toStringAsFixed(2);
  String get displayAvailableCapacityQtl => availableCapacityQtl.toStringAsFixed(2);
  String get displayOccupancyPercent => occupancyPercent.toStringAsFixed(1);

  /// Occupancy percentage, guarded against division by zero
  double get occupancyPercent =>
      totalCapacityKg <= 0.0 ? 0.0 : ((currentLoadKg / totalCapacityKg) * 100.0);

  /// Occupancy color thresholds
  bool get isSafeOccupancy => occupancyPercent < 60.0;
  bool get isModerateOccupancy => occupancyPercent >= 60.0 && occupancyPercent <= 80.0;
  bool get isNearCapacity => occupancyPercent > 80.0 && occupancyPercent < 100.0;
  bool get isOverCapacity => occupancyPercent >= 100.0;

  factory WarehouseItem.fromJson(Map<String, dynamic> json) {
    return WarehouseItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      location: json['location'] as String?,
      contactNumber: json['contact_number'] as String?,
      totalCapacityKg: _parseDouble(json['total_capacity_kg']),
      currentLoadKg: _parseDouble(json['current_load_kg']),
      managerId: json['manager_id']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      if (location != null) 'location': location,
      if (contactNumber != null) 'contact_number': contactNumber,
      'total_capacity_kg': totalCapacityKg,
      'current_load_kg': currentLoadKg,
      if (managerId != null) 'manager_id': managerId,
      'is_active': isActive,
    };
  }

  WarehouseItem copyWith({
    String? id,
    String? name,
    String? address,
    String? location,
    String? contactNumber,
    double? totalCapacityKg,
    double? currentLoadKg,
    String? managerId,
    bool? isActive,
  }) {
    return WarehouseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
      contactNumber: contactNumber ?? this.contactNumber,
      totalCapacityKg: totalCapacityKg ?? this.totalCapacityKg,
      currentLoadKg: currentLoadKg ?? this.currentLoadKg,
      managerId: managerId ?? this.managerId,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WarehouseItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          address == other.address &&
          location == other.location &&
          contactNumber == other.contactNumber &&
          totalCapacityKg == other.totalCapacityKg &&
          currentLoadKg == other.currentLoadKg &&
          managerId == other.managerId &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      address.hashCode ^
      location.hashCode ^
      contactNumber.hashCode ^
      totalCapacityKg.hashCode ^
      currentLoadKg.hashCode ^
      managerId.hashCode ^
      isActive.hashCode;

  @override
  String toString() =>
      'WarehouseItem(id: $id, name: $name, totalKg: $totalCapacityKg, currentKg: $currentLoadKg)';
}
