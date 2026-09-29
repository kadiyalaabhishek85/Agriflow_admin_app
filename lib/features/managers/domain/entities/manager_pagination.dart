import 'package:flutter/foundation.dart';

/// Pagination metadata for `PaginatedResponse[ManagerPublic]`
/// (`{page, page_size, total, total_pages}` — live OpenAPI `Pagination`).
/// `hasNext`/`hasPrevious` are derived, exactly as in FarmerPagination
/// (there is no `has_next` key in the contract).
@immutable
class ManagerPagination {
  final int page;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const ManagerPagination({
    required this.page,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory ManagerPagination.fromJson(Map<String, dynamic> json) {
    final page = (json['page'] as num?)?.toInt() ?? 1;
    final totalPages = (json['total_pages'] as num?)?.toInt() ?? 1;
    return ManagerPagination(
      page: page,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      totalRecords: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: totalPages,
      hasNext: page < totalPages,
      hasPrevious: page > 1,
    );
  }

  factory ManagerPagination.empty() {
    return const ManagerPagination(
      page: 1,
      pageSize: 20,
      totalRecords: 0,
      totalPages: 1,
      hasNext: false,
      hasPrevious: false,
    );
  }

  ManagerPagination copyWith({
    int? page,
    int? pageSize,
    int? totalRecords,
    int? totalPages,
    bool? hasNext,
    bool? hasPrevious,
  }) {
    return ManagerPagination(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalRecords: totalRecords ?? this.totalRecords,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
    );
  }
}
