import 'package:flutter/foundation.dart';
import 'seed_warehouse_brief.dart';

/// Domain entity representing a seed product from the FastAPI master catalog.
/// Strictly maps to `SeedPublic` schema from `/api/v1/seeds`.
@immutable
class SeedInventoryItem {
  final String id;
  final String name;
  final String? cropType;
  final String? variety;
  final double pricePerKg;
  final double? priceGradeA;
  final double? priceGradeB;
  final double? priceGradeC;
  final double? maxOrderQuantityKg;
  final double stockKg;
  final String? warehouseId;
  final List<String> warehouseIds;
  final List<SeedWarehouseBrief> warehouses;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  const SeedInventoryItem({
    required this.id,
    required this.name,
    this.cropType,
    this.variety,
    required this.pricePerKg,
    this.priceGradeA,
    this.priceGradeB,
    this.priceGradeC,
    this.maxOrderQuantityKg,
    required this.stockKg,
    this.warehouseId,
    this.warehouseIds = const [],
    this.warehouses = const [],
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  /// Stock quantity converted to Quintals (1 Qtl = 100 Kg).
  double get stockQtl => stockKg / 100.0;

  /// Low-stock threshold is strictly < 500 Kg (< 5 Qtl).
  bool get isLowStock => stockKg < 500.0;

  /// Clean display formatted base price.
  String get displayPrice =>
      (pricePerKg % 1 == 0) ? pricePerKg.toStringAsFixed(0) : pricePerKg.toStringAsFixed(2);

  /// Clean display formatted Grade A price.
  String? get displayPriceGradeA => priceGradeA != null
      ? ((priceGradeA! % 1 == 0) ? priceGradeA!.toStringAsFixed(0) : priceGradeA!.toStringAsFixed(2))
      : null;

  /// Clean display formatted Grade B price.
  String? get displayPriceGradeB => priceGradeB != null
      ? ((priceGradeB! % 1 == 0) ? priceGradeB!.toStringAsFixed(0) : priceGradeB!.toStringAsFixed(2))
      : null;

  /// Clean display formatted Grade C price.
  String? get displayPriceGradeC => priceGradeC != null
      ? ((priceGradeC! % 1 == 0) ? priceGradeC!.toStringAsFixed(0) : priceGradeC!.toStringAsFixed(2))
      : null;

  /// Clean display formatted max order quantity.
  String? get displayMaxOrderQuantity => maxOrderQuantityKg != null
      ? ((maxOrderQuantityKg! % 1 == 0)
          ? maxOrderQuantityKg!.toStringAsFixed(0)
          : maxOrderQuantityKg!.toStringAsFixed(2))
      : null;

  /// Clean display formatted stock in Quintals.
  String get displayStockQtl =>
      (stockQtl % 1 == 0) ? stockQtl.toStringAsFixed(0) : stockQtl.toStringAsFixed(2);

  /// Clean display formatted stock in Kilograms.
  String get displayStockKg =>
      (stockKg % 1 == 0) ? stockKg.toStringAsFixed(0) : stockKg.toStringAsFixed(2);

  /// Returns list of warehouse names assigned to this seed.
  List<String> get assignedWarehouseNames => warehouses.map((w) => w.name).toList();

  factory SeedInventoryItem.fromJson(Map<String, dynamic> json) {
    final rawWarehouseIds = json['warehouse_ids'];
    final List<String> parsedWarehouseIds = [];
    if (rawWarehouseIds is List) {
      for (final id in rawWarehouseIds) {
        if (id != null) parsedWarehouseIds.add(id.toString());
      }
    }

    final rawWarehouses = json['warehouses'];
    final List<SeedWarehouseBrief> parsedWarehouses = [];
    if (rawWarehouses is List) {
      for (final item in rawWarehouses) {
        if (item is Map<String, dynamic>) {
          parsedWarehouses.add(SeedWarehouseBrief.fromJson(item));
        }
      }
    }

    return SeedInventoryItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      cropType: json['crop_type'] as String?,
      variety: json['variety'] as String?,
      pricePerKg: _parseDouble(json['price_per_kg']),
      priceGradeA: _parseDoubleNullable(json['price_grade_a']),
      priceGradeB: _parseDoubleNullable(json['price_grade_b']),
      priceGradeC: _parseDoubleNullable(json['price_grade_c']),
      maxOrderQuantityKg: _parseDoubleNullable(json['max_order_quantity_kg']),
      stockKg: _parseDouble(json['stock_kg']),
      warehouseId: json['warehouse_id']?.toString(),
      warehouseIds: parsedWarehouseIds,
      warehouses: parsedWarehouses,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return 0.0;
  }

  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (cropType != null) 'crop_type': cropType,
      'variety': variety,
      'price_per_kg': pricePerKg.toStringAsFixed(2),
      if (priceGradeA != null) 'price_grade_a': priceGradeA!.toStringAsFixed(2),
      if (priceGradeB != null) 'price_grade_b': priceGradeB!.toStringAsFixed(2),
      if (priceGradeC != null) 'price_grade_c': priceGradeC!.toStringAsFixed(2),
      if (maxOrderQuantityKg != null)
        'max_order_quantity_kg': maxOrderQuantityKg!.toStringAsFixed(2),
      'stock_kg': stockKg.toStringAsFixed(2),
      if (warehouseId != null) 'warehouse_id': warehouseId,
      'warehouse_ids': warehouseIds,
      'warehouses': warehouses.map((w) => w.toJson()).toList(),
      'description': description,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }

  SeedInventoryItem copyWith({
    String? id,
    String? name,
    String? cropType,
    String? variety,
    double? pricePerKg,
    double? priceGradeA,
    double? priceGradeB,
    double? priceGradeC,
    double? maxOrderQuantityKg,
    double? stockKg,
    String? warehouseId,
    List<String>? warehouseIds,
    List<SeedWarehouseBrief>? warehouses,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) {
    return SeedInventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      cropType: cropType ?? this.cropType,
      variety: variety ?? this.variety,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      priceGradeA: priceGradeA ?? this.priceGradeA,
      priceGradeB: priceGradeB ?? this.priceGradeB,
      priceGradeC: priceGradeC ?? this.priceGradeC,
      maxOrderQuantityKg: maxOrderQuantityKg ?? this.maxOrderQuantityKg,
      stockKg: stockKg ?? this.stockKg,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseIds: warehouseIds ?? this.warehouseIds,
      warehouses: warehouses ?? this.warehouses,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeedInventoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          cropType == other.cropType &&
          variety == other.variety &&
          pricePerKg == other.pricePerKg &&
          priceGradeA == other.priceGradeA &&
          priceGradeB == other.priceGradeB &&
          priceGradeC == other.priceGradeC &&
          maxOrderQuantityKg == other.maxOrderQuantityKg &&
          stockKg == other.stockKg &&
          warehouseId == other.warehouseId &&
          listEquals(warehouseIds, other.warehouseIds) &&
          listEquals(warehouses, other.warehouses) &&
          description == other.description &&
          imageUrl == other.imageUrl &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      cropType.hashCode ^
      variety.hashCode ^
      pricePerKg.hashCode ^
      priceGradeA.hashCode ^
      priceGradeB.hashCode ^
      priceGradeC.hashCode ^
      maxOrderQuantityKg.hashCode ^
      stockKg.hashCode ^
      warehouseId.hashCode ^
      Object.hashAll(warehouseIds) ^
      Object.hashAll(warehouses) ^
      description.hashCode ^
      imageUrl.hashCode ^
      isActive.hashCode;

  @override
  String toString() =>
      'SeedInventoryItem(id: $id, name: $name, variety: $variety, price: $pricePerKg, stock: $stockKg, warehouses: ${warehouses.length}, active: $isActive)';
}
