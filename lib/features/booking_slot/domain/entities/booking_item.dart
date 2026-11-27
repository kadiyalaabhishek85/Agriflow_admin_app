class BookingItem {
  // -------------------------------------------------------------
  // Backend-Native Fields (strictly matching BookingPublic schema)
  // -------------------------------------------------------------
  final String id;
  final String farmerId;
  final String warehouseId;
  final String? warehouseSlotId;
  final String? grainSaleId;
  final String bookingDate; // YYYY-MM-DD
  final String grainType;
  final double quantityKg;
  final String status;
  final String? notes;

  // -------------------------------------------------------------
  // Enriched Display Fields (resolved via relationship lookup)
  // -------------------------------------------------------------
  final String? enrichedFarmerName;
  final String? enrichedFarmerPhone;
  final String? enrichedWarehouseName;
  final String? enrichedWarehouseAddress;
  final String? enrichedSlotTime;

  const BookingItem({
    required this.id,
    required this.farmerId,
    required this.warehouseId,
    this.warehouseSlotId,
    this.grainSaleId,
    required this.bookingDate,
    required this.grainType,
    required this.quantityKg,
    required this.status,
    this.notes,
    this.enrichedFarmerName,
    this.enrichedFarmerPhone,
    this.enrichedWarehouseName,
    this.enrichedWarehouseAddress,
    this.enrichedSlotTime,
  });

  /// Factory strictly parsing backend JSON
  factory BookingItem.fromJson(Map<String, dynamic> json) {
    return BookingItem(
      id: (json['id'] ?? '').toString(),
      farmerId: (json['farmer_id'] ?? '').toString(),
      warehouseId: (json['warehouse_id'] ?? '').toString(),
      warehouseSlotId: json['warehouse_slot_id']?.toString(),
      grainSaleId: json['grain_sale_id']?.toString(),
      bookingDate: (json['booking_date'] ?? '').toString(),
      grainType: (json['grain_type'] ?? 'General Grain').toString(),
      quantityKg: double.tryParse((json['quantity_kg'] ?? '0').toString()) ?? 0.0,
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      notes: json['notes']?.toString(),
      enrichedSlotTime: json['slot_time']?.toString(),
    );
  }

  /// Create a copy with enriched display metadata
  BookingItem copyWithEnrichment({
    String? farmerName,
    String? farmerPhone,
    String? warehouseName,
    String? warehouseAddress,
    String? slotTime,
  }) {
    return BookingItem(
      id: id,
      farmerId: farmerId,
      warehouseId: warehouseId,
      warehouseSlotId: warehouseSlotId,
      grainSaleId: grainSaleId,
      bookingDate: bookingDate,
      grainType: grainType,
      quantityKg: quantityKg,
      status: status,
      notes: notes,
      enrichedFarmerName: farmerName ?? enrichedFarmerName,
      enrichedFarmerPhone: farmerPhone ?? enrichedFarmerPhone,
      enrichedWarehouseName: warehouseName ?? enrichedWarehouseName,
      enrichedWarehouseAddress: warehouseAddress ?? enrichedWarehouseAddress,
      enrichedSlotTime: slotTime ?? enrichedSlotTime,
    );
  }

  /// Create a copy with authoritative updated status from backend mutation
  BookingItem copyWithStatus(String newStatus, {String? newNotes}) {
    return BookingItem(
      id: id,
      farmerId: farmerId,
      warehouseId: warehouseId,
      warehouseSlotId: warehouseSlotId,
      grainSaleId: grainSaleId,
      bookingDate: bookingDate,
      grainType: grainType,
      quantityKg: quantityKg,
      status: newStatus.toLowerCase(),
      notes: newNotes ?? notes,
      enrichedFarmerName: enrichedFarmerName,
      enrichedFarmerPhone: enrichedFarmerPhone,
      enrichedWarehouseName: enrichedWarehouseName,
      enrichedWarehouseAddress: enrichedWarehouseAddress,
      enrichedSlotTime: enrichedSlotTime,
    );
  }

  // Presentation helpers
  String get displayName =>
      enrichedFarmerName?.isNotEmpty == true
          ? enrichedFarmerName!
          : 'Farmer #${farmerId.length > 6 ? farmerId.substring(0, 6) : farmerId}';

  String get displayPhone => enrichedFarmerPhone ?? '';

  String get displayWarehouse =>
      enrichedWarehouseName?.isNotEmpty == true
          ? enrichedWarehouseName!
          : 'Warehouse #${warehouseId.length > 6 ? warehouseId.substring(0, 6) : warehouseId}';

  String get displayAddress => enrichedWarehouseAddress ?? '';

  double get quantityQtl => quantityKg / 100.0;

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isDelivered => status == 'delivered';
  bool get isInspected => status == 'inspected';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
