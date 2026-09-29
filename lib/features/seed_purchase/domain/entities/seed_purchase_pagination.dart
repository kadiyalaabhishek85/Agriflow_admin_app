class SeedPurchasePagination {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const SeedPurchasePagination({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory SeedPurchasePagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SeedPurchasePagination(
        page: 1,
        pageSize: 20,
        total: 0,
        totalPages: 0,
      );
    }
    return SeedPurchasePagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
    );
  }

  factory SeedPurchasePagination.empty() {
    return const SeedPurchasePagination(
      page: 1,
      pageSize: 20,
      total: 0,
      totalPages: 0,
    );
  }
}
