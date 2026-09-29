import '../../domain/entities/bank_change_request_item.dart';
import '../../domain/entities/farmer_item.dart';
import '../../domain/entities/farmer_pagination.dart';
import '../../domain/repositories/farmer_repository.dart';
import '../datasources/farmer_remote_data_source.dart';

/// Concrete implementation of [FarmerRepository].
class FarmerRepositoryImpl implements FarmerRepository {
  final FarmerRemoteDataSource remoteDataSource;
  final Map<String, ({String name, String phone, String? village})> _farmersCache = {};

  FarmerRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<({List<FarmerItem> items, FarmerPagination pagination})> getFarmers({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String sort = 'created_at',
    String order = 'desc',
  }) async {
    final result = await remoteDataSource.getFarmers(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
      sort: sort,
      order: order,
    );

    // Update lookup cache
    for (final farmer in result.items) {
      _farmersCache[farmer.id] = (
        name: farmer.name,
        phone: farmer.phone,
        village: farmer.villageOrAddress.isNotEmpty ? farmer.villageOrAddress : null,
      );
    }

    return result;
  }

  @override
  Future<FarmerItem> getFarmerDetail({
    required String accessToken,
    required String farmerId,
  }) async {
    final item = await remoteDataSource.getFarmerDetail(
      accessToken: accessToken,
      farmerId: farmerId,
    );
    _farmersCache[item.id] = (
      name: item.name,
      phone: item.phone,
      village: item.villageOrAddress.isNotEmpty ? item.villageOrAddress : null,
    );
    return item;
  }

  @override
  Future<FarmerItem> setFarmerApproval({
    required String accessToken,
    required String farmerId,
    required String status,
  }) async {
    return await remoteDataSource.setFarmerApproval(
      accessToken: accessToken,
      farmerId: farmerId,
      status: status,
    );
  }

  @override
  Future<FarmerItem> updateFarmerProfile({
    required String accessToken,
    required String farmerId,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? acresOfLand,
    String? soilType,
    String? irrigationType,
    String? primaryCrop,
    String? secondaryCrop,
  }) async {
    final item = await remoteDataSource.updateFarmerProfile(
      accessToken: accessToken,
      farmerId: farmerId,
      name: name,
      phone: phone,
      email: email,
      address: address,
      acresOfLand: acresOfLand,
      soilType: soilType,
      irrigationType: irrigationType,
      primaryCrop: primaryCrop,
      secondaryCrop: secondaryCrop,
    );
    _farmersCache[item.id] = (
      name: item.name,
      phone: item.phone,
      village: item.villageOrAddress.isNotEmpty ? item.villageOrAddress : null,
    );
    return item;
  }

  @override
  Future<FarmerItem> createFarmer({
    required String accessToken,
    required String name,
    required String phone,
    required String password,
    String? email,
    String? address,
    double? acresOfLand,
    String? cropAddress,
  }) async {
    return await remoteDataSource.createFarmer(
      accessToken: accessToken,
      name: name,
      phone: phone,
      password: password,
      email: email,
      address: address,
      acresOfLand: acresOfLand,
      cropAddress: cropAddress,
    );
  }

  @override
  Future<({List<BankChangeRequestItem> items, FarmerPagination pagination})> getBankChangeRequests({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String sort = 'created_at',
    String order = 'desc',
  }) async {
    // Warm the farmer lookup first so enrichment never races the cache (flutter-03 rec 8)
    await getFarmerLookup(accessToken: accessToken);

    final result = await remoteDataSource.getBankChangeRequests(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
      sort: sort,
      order: order,
    );

    // Enrich bank requests with farmer name/phone if available
    final enrichedItems = result.items.map((req) {
      final lookup = _farmersCache[req.farmerId];
      if (lookup != null) {
        return req.copyWithEnrichment(
          farmerName: lookup.name,
          farmerPhone: lookup.phone,
        );
      }
      return req;
    }).toList();

    return (items: enrichedItems, pagination: result.pagination);
  }

  @override
  Future<void> reviewBankChangeRequest({
    required String accessToken,
    required String requestId,
    required bool approve,
    String? adminNotes,
  }) async {
    return await remoteDataSource.reviewBankChangeRequest(
      accessToken: accessToken,
      requestId: requestId,
      approve: approve,
      adminNotes: adminNotes,
    );
  }

  @override
  Future<Map<String, ({String name, String phone, String? village})>> getFarmerLookup({
    required String accessToken,
  }) async {
    if (_farmersCache.isNotEmpty) {
      return _farmersCache;
    }

    try {
      final result = await remoteDataSource.getFarmers(
        accessToken: accessToken,
        page: 1,
        pageSize: 100,
      );
      for (final farmer in result.items) {
        _farmersCache[farmer.id] = (
          name: farmer.name,
          phone: farmer.phone,
          village: farmer.villageOrAddress.isNotEmpty ? farmer.villageOrAddress : null,
        );
      }
    } catch (_) {
      // Lookup error should not crash callers
    }
    return _farmersCache;
  }
}
