class BookingPagination {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const BookingPagination({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory BookingPagination.fromJson(Map<String, dynamic> json) {
    return BookingPagination(
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }

  factory BookingPagination.empty() {
    return const BookingPagination(
      page: 1,
      pageSize: 20,
      total: 0,
      totalPages: 1,
    );
  }
}
