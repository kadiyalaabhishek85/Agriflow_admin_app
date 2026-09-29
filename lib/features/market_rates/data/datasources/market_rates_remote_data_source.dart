import '../../domain/entities/market_rate_item.dart';

/// Abstract remote data source contract for Market Rates.
abstract class MarketRatesRemoteDataSource {
  /// `GET /api/v1/market-rates` with bearer token, falling back to
  /// `GET /api/v1/public/market-rates` (read-only, identical payload).
  Future<List<MarketRateItem>> getRates({required String accessToken});

  /// `GET /api/v1/public/market-rates` — anonymous read.
  Future<List<MarketRateItem>> getPublicRates();

  /// `POST /api/v1/market-rates` — Set Market Rate for one grade.
  Future<void> setRate({
    required String accessToken,
    required String cropType,
    required String grade,
    required double pricePerKg,
    required String effectiveDate,
  });
}
