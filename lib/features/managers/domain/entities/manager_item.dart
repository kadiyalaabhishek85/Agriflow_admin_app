import 'package:agriflow_admin/core/utils/app_initials.dart';
import 'package:flutter/foundation.dart';

/// Manager/super-admin account as returned by `ManagerPublic`
/// (live OpenAPI, verified 2026-09-28).
@immutable
class ManagerItem {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String role; // farmer | manager | super_admin (UserRole)
  final String status; // pending | active | rejected | suspended (UserStatus)
  final String? assignedRegion;
  final String? department;
  final DateTime createdAt;

  const ManagerItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.status,
    this.assignedRegion,
    this.department,
    required this.createdAt,
  });

  factory ManagerItem.fromJson(Map<String, dynamic> json) {
    return ManagerItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'manager',
      status: json['status'] as String? ?? 'active',
      assignedRegion: json['assigned_region'] as String?,
      department: json['department'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime(2026, 1, 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'status': status,
      'assigned_region': assignedRegion,
      'department': department,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isSuperAdmin => role == 'super_admin';

  /// 'SS' style initials for the avatar.
  String get initials => AppInitials.of(name, fallback: '?');

  ManagerItem copyWith({
    String? name,
    String? phone,
    String? email,
    String? role,
    String? status,
    String? assignedRegion,
    String? department,
  }) {
    return ManagerItem(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      assignedRegion: assignedRegion ?? this.assignedRegion,
      department: department ?? this.department,
      createdAt: createdAt,
    );
  }
}
