/// Typed exception hierarchy for the Market Rates domain.
class MarketRatesException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  const MarketRatesException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}

class MarketRatesUnauthorizedException extends MarketRatesException {
  const MarketRatesUnauthorizedException({
    super.message = 'Session expired. Please log in again.',
  }) : super(statusCode: 401);
}

class MarketRatesForbiddenException extends MarketRatesException {
  const MarketRatesForbiddenException({
    super.message = 'You do not have permission to perform this action.',
  }) : super(statusCode: 403);
}

class MarketRatesNotFoundException extends MarketRatesException {
  const MarketRatesNotFoundException({
    super.message = 'Market rate not found.',
  }) : super(statusCode: 404);
}

class MarketRatesValidationException extends MarketRatesException {
  const MarketRatesValidationException({required super.message})
      : super(statusCode: 422);
}

class MarketRatesServerException extends MarketRatesException {
  const MarketRatesServerException({
    super.message = 'Backend server error. Please try again later.',
  }) : super(statusCode: 500);
}
