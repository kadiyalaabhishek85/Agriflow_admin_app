class SeedCatalogItem {
  final String id;
  final String name;
  final String? variety;
  final double pricePerKg;
  final double stockKg;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  const SeedCatalogItem({
    required this.id,
    required this.name,
    this.variety,
    required this.pricePerKg,
    required this.stockKg,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  factory SeedCatalogItem.fromJson(Map<String, dynamic> json) {
    return SeedCatalogItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown Seed').toString(),
      variety: json['variety']?.toString(),
      pricePerKg: double.tryParse((json['price_per_kg'] ?? '0').toString()) ?? 0.0,
      stockKg: double.tryParse((json['stock_kg'] ?? '0').toString()) ?? 0.0,
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      isActive: json['is_active'] == true,
    );
  }
}
