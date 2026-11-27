import 'package:agriflow_admin/core/utils/app_dates.dart';
import 'package:flutter/foundation.dart';

/// Audit log entry entity (`AuditLogPublic` from
/// `GET /api/v1/admin/audit-logs`).
@immutable
class AuditLogItem {
  final String id;
  final String? userId;
  final String? actorName;
  final String? actorRole;
  final String action;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final String? details;
  final String createdAt;

  const AuditLogItem({
    required this.id,
    required this.userId,
    this.actorName,
    this.actorRole,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.oldValue,
    required this.newValue,
    required this.details,
    required this.createdAt,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    return AuditLogItem(
      id: (json['id'] as String?) ?? '',
      userId: json['user_id'] as String?,
      actorName: json['actor_name'] as String?,
      actorRole: json['actor_role'] as String?,
      action: (json['action'] as String?) ?? '',
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      oldValue: json['old_value'] is Map<String, dynamic>
          ? json['old_value'] as Map<String, dynamic>
          : null,
      newValue: json['new_value'] is Map<String, dynamic>
          ? json['new_value'] as Map<String, dynamic>
          : null,
      details: json['details'] as String?,
      createdAt: (json['created_at'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'actor_name': actorName,
        'actor_role': actorRole,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'old_value': oldValue,
        'new_value': newValue,
        'details': details,
        'created_at': createdAt,
      };

  /// Short display date: `2026-09-28T10:32:11Z` → `28 Sep 2026, 10:32`.
  String get createdLabel =>
      AppDates.isoDateTimeLabel(createdAt, fallback: createdAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AuditLogItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
