class WarehouseItem {
  final String id;
  final String name;
  final String address;
  final double totalCapacityKg;
  final double currentLoadKg;
  final bool isActive;

  const WarehouseItem({
    required this.id,
    required this.name,
    required this.address,
    required this.totalCapacityKg,
    required this.currentLoadKg,
    required this.isActive,
  });

  factory WarehouseItem.fromJson(Map<String, dynamic> json) {
    return WarehouseItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      totalCapacityKg: double.tryParse((json['total_capacity_kg'] ?? '0').toString()) ?? 0.0,
      currentLoadKg: double.tryParse((json['current_load_kg'] ?? '0').toString()) ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
