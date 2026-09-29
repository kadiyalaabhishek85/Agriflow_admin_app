/// Standard pagination metadata strictly matching the backend contract
class FarmVisitPagination {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const FarmVisitPagination({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory FarmVisitPagination.fromJson(Map<String, dynamic> json) {
    return FarmVisitPagination(
      page: json['page'] is num
          ? (json['page'] as num).toInt()
          : int.tryParse(json['page']?.toString() ?? '1') ?? 1,
      pageSize: json['page_size'] is num
          ? (json['page_size'] as num).toInt()
          : int.tryParse(json['page_size']?.toString() ?? '20') ?? 20,
      total: json['total'] is num
          ? (json['total'] as num).toInt()
          : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      totalPages: json['total_pages'] is num
          ? (json['total_pages'] as num).toInt()
          : int.tryParse(json['total_pages']?.toString() ?? '1') ?? 1,
    );
  }

  bool get hasMore => page < totalPages;
}
