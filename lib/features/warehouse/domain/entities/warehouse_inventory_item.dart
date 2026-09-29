import 'package:flutter/foundation.dart';

/// Domain entity representing a stored grain stock breakdown in a warehouse.
/// Maps strictly to `WarehouseInventoryPublic` from the FastAPI backend.
@immutable
class WarehouseInventoryItem {
  final String id;
  final String warehouseId;
  final String grainType;
  final double quantityKg;

  const WarehouseInventoryItem({
    required this.id,
    required this.warehouseId,
    required this.grainType,
    required this.quantityKg,
  });

  /// 1 Quintal (Qtl) = 100 Kilograms (Kg)
  double get quantityQtl => quantityKg / 100.0;

  /// Display string helpers
  String get displayQuantityQtl => quantityQtl.toStringAsFixed(2);
  String get displayQuantityKg => quantityKg.toStringAsFixed(0);

  factory WarehouseInventoryItem.fromJson(Map<String, dynamic> json) {
    return WarehouseInventoryItem(
      id: (json['id'] ?? '').toString(),
      warehouseId: (json['warehouse_id'] ?? '').toString(),
      grainType: (json['grain_type'] ?? '').toString(),
      quantityKg: _parseDouble(json['quantity_kg']),
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
      'warehouse_id': warehouseId,
      'grain_type': grainType,
      'quantity_kg': quantityKg.toStringAsFixed(2),
    };
  }

  WarehouseInventoryItem copyWith({
    String? id,
    String? warehouseId,
    String? grainType,
    double? quantityKg,
  }) {
    return WarehouseInventoryItem(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      grainType: grainType ?? this.grainType,
      quantityKg: quantityKg ?? this.quantityKg,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WarehouseInventoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          warehouseId == other.warehouseId &&
          grainType == other.grainType &&
          quantityKg == other.quantityKg;

  @override
  int get hashCode =>
      id.hashCode ^ warehouseId.hashCode ^ grainType.hashCode ^ quantityKg.hashCode;

  @override
  String toString() =>
      'WarehouseInventoryItem(id: $id, grainType: $grainType, quantityKg: $quantityKg)';
}
