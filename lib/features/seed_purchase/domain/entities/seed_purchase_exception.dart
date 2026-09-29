class SeedPurchaseException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  const SeedPurchaseException(
    this.message, {
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}
