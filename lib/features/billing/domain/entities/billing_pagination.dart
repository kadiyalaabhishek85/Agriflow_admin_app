import 'package:flutter/foundation.dart';

/// Pagination value object matching FastAPI `Pagination` schema.
@immutable
class BillingPagination {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const BillingPagination({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory BillingPagination.fromJson(Map<String, dynamic> json) {
    return BillingPagination(
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }

  bool get hasMore => page < totalPages;

  BillingPagination copyWith({
    int? page,
    int? pageSize,
    int? total,
    int? totalPages,
  }) {
    return BillingPagination(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
