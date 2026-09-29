import '../../domain/entities/market_rate_item.dart';
import '../../domain/repositories/market_rates_repository.dart';
import '../datasources/market_rates_remote_data_source.dart';

/// Implementation of MarketRatesRepository communicating with
/// MarketRatesRemoteDataSource.
class MarketRatesRepositoryImpl implements MarketRatesRepository {
  final MarketRatesRemoteDataSource remoteDataSource;

  MarketRatesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MarketRateItem>> getRates({required String accessToken}) {
    return remoteDataSource.getRates(accessToken: accessToken);
  }

  @override
  Future<void> setRate({
    required String accessToken,
    required String cropType,
    required String grade,
    required double pricePerKg,
    required String effectiveDate,
  }) {
    return remoteDataSource.setRate(
      accessToken: accessToken,
      cropType: cropType,
      grade: grade,
      pricePerKg: pricePerKg,
      effectiveDate: effectiveDate,
    );
  }
}
