import 'package:flutter/foundation.dart';

/// Pagination value object matching FastAPI `Pagination` schema.
@immutable
class GrainSalePagination {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const GrainSalePagination({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory GrainSalePagination.fromJson(Map<String, dynamic> json) {
    return GrainSalePagination(
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }

  bool get hasMore => page < totalPages;

  GrainSalePagination copyWith({
    int? page,
    int? pageSize,
    int? total,
    int? totalPages,
  }) {
    return GrainSalePagination(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
