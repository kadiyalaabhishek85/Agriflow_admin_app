class SeedPurchaseItem {
  // -------------------------------------------------------------
  // Backend-Native Fields (strictly matching SeedPurchasePublic schema)
  // -------------------------------------------------------------
  final String id;
  final String farmerId;
  final String seedId;
  final double quantityKg;
  final double pricePerKg;
  final double totalAmount;
  final String paymentStatus;
  final String? invoiceNumber;
  final DateTime? createdAt;

  // -------------------------------------------------------------
  // Enriched Display Fields (resolved via relationship lookup)
  // -------------------------------------------------------------
  final String? enrichedFarmerName;
  final String? enrichedFarmerPhone;
  final String? enrichedSeedName;
  final String? enrichedSeedVariety;

  const SeedPurchaseItem({
    required this.id,
    required this.farmerId,
    required this.seedId,
    required this.quantityKg,
    required this.pricePerKg,
    required this.totalAmount,
    required this.paymentStatus,
    this.invoiceNumber,
    this.createdAt,
    this.enrichedFarmerName,
    this.enrichedFarmerPhone,
    this.enrichedSeedName,
    this.enrichedSeedVariety,
  });

  /// Factory strictly parsing backend JSON
  factory SeedPurchaseItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final dateRaw = json['created_at'];
    if (dateRaw != null) {
      parsedDate = DateTime.tryParse(dateRaw.toString());
    }

    return SeedPurchaseItem(
      id: (json['id'] ?? '').toString(),
      farmerId: (json['farmer_id'] ?? '').toString(),
      seedId: (json['seed_id'] ?? '').toString(),
      quantityKg: double.tryParse((json['quantity_kg'] ?? '0').toString()) ?? 0.0,
      pricePerKg: double.tryParse((json['price_per_kg'] ?? '0').toString()) ?? 0.0,
      totalAmount: double.tryParse((json['total_amount'] ?? '0').toString()) ?? 0.0,
      paymentStatus: (json['payment_status'] ?? 'pending').toString().toLowerCase(),
      invoiceNumber: json['invoice_number']?.toString(),
      createdAt: parsedDate,
    );
  }

  /// Create a copy with enriched display metadata
  SeedPurchaseItem copyWithEnrichment({
    String? farmerName,
    String? farmerPhone,
    String? seedName,
    String? seedVariety,
  }) {
    return SeedPurchaseItem(
      id: id,
      farmerId: farmerId,
      seedId: seedId,
      quantityKg: quantityKg,
      pricePerKg: pricePerKg,
      totalAmount: totalAmount,
      paymentStatus: paymentStatus,
      invoiceNumber: invoiceNumber,
      createdAt: createdAt,
      enrichedFarmerName: farmerName ?? enrichedFarmerName,
      enrichedFarmerPhone: farmerPhone ?? enrichedFarmerPhone,
      enrichedSeedName: seedName ?? enrichedSeedName,
      enrichedSeedVariety: seedVariety ?? enrichedSeedVariety,
    );
  }

  /// Create a copy with authoritative updated status from backend mutation
  SeedPurchaseItem copyWithStatus(String newStatus) {
    return SeedPurchaseItem(
      id: id,
      farmerId: farmerId,
      seedId: seedId,
      quantityKg: quantityKg,
      pricePerKg: pricePerKg,
      totalAmount: totalAmount,
      paymentStatus: newStatus.toLowerCase(),
      invoiceNumber: invoiceNumber,
      createdAt: createdAt,
      enrichedFarmerName: enrichedFarmerName,
      enrichedFarmerPhone: enrichedFarmerPhone,
      enrichedSeedName: enrichedSeedName,
      enrichedSeedVariety: enrichedSeedVariety,
    );
  }

  // Helper getters for presentation
  String get displayName =>
      enrichedFarmerName?.isNotEmpty == true ? enrichedFarmerName! : 'Farmer #${farmerId.length > 6 ? farmerId.substring(0, 6) : farmerId}';

  String get displayPhone => enrichedFarmerPhone ?? '';

  String get displaySeed =>
      enrichedSeedName?.isNotEmpty == true ? enrichedSeedName! : 'Seed #${seedId.length > 6 ? seedId.substring(0, 6) : seedId}';

  String get displayVariety => enrichedSeedVariety ?? '';

  double get quantityQtl => quantityKg / 100.0;

  bool get isPending => paymentStatus == 'pending';
  bool get isPaid => paymentStatus == 'paid';
  bool get isFailed => paymentStatus == 'failed';
}
