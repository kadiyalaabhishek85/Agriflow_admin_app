import 'package:flutter/foundation.dart';

/// Pagination metadata for audit log lists (`Pagination` schema:
/// page, page_size, total, total_pages).
@immutable
class AuditLogPagination {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const AuditLogPagination({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory AuditLogPagination.fromJson(Map<String, dynamic> json) {
    return AuditLogPagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
    );
  }

  factory AuditLogPagination.empty() => const AuditLogPagination(
        page: 1,
        pageSize: 20,
        total: 0,
        totalPages: 1,
      );

  int get totalRecords => total;
  bool get hasNext => page < totalPages;
  bool get hasPrevious => page > 1;

  AuditLogPagination copyWith({
    int? page,
    int? pageSize,
    int? total,
    int? totalPages,
  }) {
    return AuditLogPagination(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
