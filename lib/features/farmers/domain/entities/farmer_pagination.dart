import 'package:flutter/foundation.dart';

/// Models pagination metadata returned by FastAPI `PaginatedResponse[FarmerAdminView]`.
@immutable
class FarmerPagination {
  final int page;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const FarmerPagination({
    required this.page,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory FarmerPagination.fromJson(Map<String, dynamic> json) {
    final page = (json['page'] as num?)?.toInt() ?? 1;
    final totalPages = (json['total_pages'] as num?)?.toInt() ?? 1;
    return FarmerPagination(
      page: page,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      totalRecords: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: totalPages,
      hasNext: page < totalPages,
      hasPrevious: page > 1,
    );
  }

  factory FarmerPagination.empty() {
    return const FarmerPagination(
      page: 1,
      pageSize: 20,
      totalRecords: 0,
      totalPages: 1,
      hasNext: false,
      hasPrevious: false,
    );
  }

  FarmerPagination copyWith({
    int? page,
    int? pageSize,
    int? totalRecords,
    int? totalPages,
    bool? hasNext,
    bool? hasPrevious,
  }) {
    return FarmerPagination(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalRecords: totalRecords ?? this.totalRecords,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
    );
  }
}
