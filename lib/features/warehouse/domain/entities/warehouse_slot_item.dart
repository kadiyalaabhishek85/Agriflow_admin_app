import 'package:flutter/foundation.dart';

/// Domain entity representing a booking window / procurement slot at a warehouse.
/// Maps strictly to `WarehouseSlotPublic` from the FastAPI backend.
@immutable
class WarehouseSlotItem {
  final String id;
  final String warehouseId;
  final String slotDate;
  final String startTime;
  final String endTime;
  final double capacityKg;
  final double bookedKg;
  final String status;

  const WarehouseSlotItem({
    required this.id,
    required this.warehouseId,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.capacityKg,
    required this.bookedKg,
    required this.status,
  });

  /// 1 Quintal (Qtl) = 100 Kilograms (Kg)
  double get capacityQtl => capacityKg / 100.0;
  double get bookedQtl => bookedKg / 100.0;

  double get availableCapacityKg =>
      (capacityKg - bookedKg).clamp(0.0, double.infinity);
  double get availableCapacityQtl => availableCapacityKg / 100.0;

  double get availableKg => availableCapacityKg;
  double get availableQtl => availableCapacityQtl;

  double get occupancyPercent =>
      capacityKg <= 0.0 ? 0.0 : ((bookedKg / capacityKg) * 100.0);

  bool get isActive => status.toLowerCase() == 'active';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  static String _formatTime(String t) {
    if (t.length >= 5) return t.substring(0, 5);
    return t;
  }

  String get timeRangeLabel => '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  String get displayTimeRange => timeRangeLabel;

  factory WarehouseSlotItem.fromJson(Map<String, dynamic> json) {
    return WarehouseSlotItem(
      id: (json['id'] ?? '').toString(),
      warehouseId: (json['warehouse_id'] ?? '').toString(),
      slotDate: (json['slot_date'] ?? '').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      capacityKg: _parseDouble(json['capacity_kg']),
      bookedKg: _parseDouble(json['booked_kg']),
      status: (json['status'] ?? 'active').toString(),
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
      'slot_date': slotDate,
      'start_time': startTime,
      'end_time': endTime,
      'capacity_kg': capacityKg.toStringAsFixed(2),
      'booked_kg': bookedKg.toStringAsFixed(2),
      'status': status,
    };
  }

  WarehouseSlotItem copyWith({
    String? id,
    String? warehouseId,
    String? slotDate,
    String? startTime,
    String? endTime,
    double? capacityKg,
    double? bookedKg,
    String? status,
  }) {
    return WarehouseSlotItem(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      slotDate: slotDate ?? this.slotDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      capacityKg: capacityKg ?? this.capacityKg,
      bookedKg: bookedKg ?? this.bookedKg,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WarehouseSlotItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          warehouseId == other.warehouseId &&
          slotDate == other.slotDate &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          capacityKg == other.capacityKg &&
          bookedKg == other.bookedKg &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      warehouseId.hashCode ^
      slotDate.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      capacityKg.hashCode ^
      bookedKg.hashCode ^
      status.hashCode;

  @override
  String toString() =>
      'WarehouseSlotItem(id: $id, date: $slotDate, time: $timeRangeLabel, booked: $bookedKg/$capacityKg, status: $status)';
}
