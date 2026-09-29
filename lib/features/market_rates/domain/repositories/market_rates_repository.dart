import '../entities/market_rate_item.dart';

/// Abstract repository contract for Market Rates data access.
///
/// Verified FastAPI contract only:
/// - `GET /api/v1/market-rates` (authenticated list; the implementation may
///   read-fallback to `GET /api/v1/public/market-rates`, identical payload)
/// - `POST /api/v1/market-rates` (Set Market Rate, one grade per request)
///
/// There is no PATCH/PUT/DELETE endpoint in the contract — editing and
/// deleting rates are intentionally not part of this repository.
abstract class MarketRatesRepository {
  /// Fetches the full market rate board.
  Future<List<MarketRateItem>> getRates({required String accessToken});

  /// Sets a single grade rate via `MarketRateCreate`
  /// (`crop_type`, `grade`, `price_per_kg`, `effective_date`).
  Future<void> setRate({
    required String accessToken,
    required String cropType,
    required String grade,
    required double pricePerKg,
    required String effectiveDate,
  });
}
