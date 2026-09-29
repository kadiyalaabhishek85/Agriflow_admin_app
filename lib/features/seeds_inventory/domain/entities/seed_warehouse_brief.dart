import 'package:flutter/foundation.dart';

/// Domain entity representing a warehouse summary associated with a seed product.
/// Strictly maps to `#/components/schemas/WarehouseBrief` from the FastAPI backend.
@immutable
class SeedWarehouseBrief {
  final String id;
  final String name;
  final String? address;
  final String? location;
  final String? contactNumber;

  const SeedWarehouseBrief({
    required this.id,
    required this.name,
    this.address,
    this.location,
    this.contactNumber,
  });

  factory SeedWarehouseBrief.fromJson(Map<String, dynamic> json) {
    return SeedWarehouseBrief(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address'] as String?,
      location: json['location'] as String?,
      contactNumber: json['contact_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (address != null) 'address': address,
      if (location != null) 'location': location,
      if (contactNumber != null) 'contact_number': contactNumber,
    };
  }

  SeedWarehouseBrief copyWith({
    String? id,
    String? name,
    String? address,
    String? location,
    String? contactNumber,
  }) {
    return SeedWarehouseBrief(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
      contactNumber: contactNumber ?? this.contactNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeedWarehouseBrief &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          address == other.address &&
          location == other.location &&
          contactNumber == other.contactNumber;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      address.hashCode ^
      location.hashCode ^
      contactNumber.hashCode;

  @override
  String toString() => 'SeedWarehouseBrief(id: $id, name: $name)';
}
