import '../../../booking_slot/data/datasources/booking_remote_data_source.dart';
import '../../../booking_slot/domain/entities/booking_exception.dart';
import '../../domain/entities/grain_sale_exception.dart';
import '../../domain/entities/grain_sale_item.dart';
import '../../domain/entities/grain_sale_pagination.dart';
import '../../domain/repositories/grain_sale_repository.dart';
import '../datasources/grain_sale_remote_data_source.dart';

/// Production implementation of GrainSaleRepository.
class GrainSaleRepositoryImpl implements GrainSaleRepository {
  final GrainSaleRemoteDataSource remoteDataSource;
  final BookingRemoteDataSource bookingDataSource;

  // Cached lookups
  Map<String, ({String name, String phone, String? village})>? _farmerCache;

  GrainSaleRepositoryImpl({
    required this.remoteDataSource,
    required this.bookingDataSource,
  });

  @override
  Future<Map<String, ({String name, String phone, String? village})>> getFarmerLookup({
    required String accessToken,
  }) async {
    if (_farmerCache != null && _farmerCache!.isNotEmpty) {
      return _farmerCache!;
    }
    try {
      _farmerCache = await remoteDataSource.getFarmers(accessToken: accessToken);
      return _farmerCache!;
    } catch (_) {
      return _farmerCache ?? {};
    }
  }

  @override
  Future<({List<GrainSaleItem> items, GrainSalePagination pagination})> getGrainSales({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? sort,
    String? order,
  }) async {
    // Fetch grain sales and farmer catalog in parallel if cache is empty
    final results = await Future.wait([
      remoteDataSource.getGrainSales(
        accessToken: accessToken,
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        sort: sort,
        order: order,
      ),
      if (_farmerCache == null)
        remoteDataSource.getFarmers(accessToken: accessToken).catchError(
              (_) => <String, ({String name, String phone, String? village})>{},
            )
      else
        Future.value(_farmerCache!),
    ]);

    final salesData = results[0] as ({List<GrainSaleItem> items, GrainSalePagination pagination});
    _farmerCache = results[1] as Map<String, ({String name, String phone, String? village})>;

    final enrichedItems = salesData.items.map((sale) {
      final farmer = _farmerCache?[sale.farmerId];
      if (farmer != null) {
        return sale.copyWithEnrichment(
          farmerName: farmer.name,
          farmerPhone: farmer.phone,
          farmerVillage: farmer.village,
        );
      }
      return sale;
    }).toList();

    return (items: enrichedItems, pagination: salesData.pagination);
  }

  @override
  Future<GrainSaleItem> procureCrop({
    required String accessToken,
    required String farmerId,
    required String grainType,
    required String grade,
    required double rawMaterialKg,
    required double goodMaterialKg,
    required double wastageKg,
  }) async {
    final item = await remoteDataSource.procureCrop(
      accessToken: accessToken,
      farmerId: farmerId,
      grainType: grainType,
      grade: grade,
      rawMaterialKg: rawMaterialKg,
      goodMaterialKg: goodMaterialKg,
      wastageKg: wastageKg,
    );

    final farmer = _farmerCache?[item.farmerId];
    if (farmer != null) {
      return item.copyWithEnrichment(
        farmerName: farmer.name,
        farmerPhone: farmer.phone,
        farmerVillage: farmer.village,
      );
    }
    return item;
  }

  /// Resolves the real booking slot id for a sale by joining `GET /bookings`
  /// rows on `grain_sale_id`; never falls back to the sale id.
  Future<String> _resolveBookingSlotId({
    required String accessToken,
    required String saleId,
  }) async {
    if (saleId.isNotEmpty) {
      try {
        var page = 1;
        var totalPages = 1;
        while (page <= totalPages) {
          final result = await bookingDataSource.getBookings(
            accessToken: accessToken,
            page: page,
            pageSize: 100,
          );
          for (final booking in result.items) {
            if (booking.grainSaleId == saleId) {
              return booking.id;
            }
          }
          totalPages = result.pagination.totalPages;
          page++;
        }
      } on BookingException catch (e) {
        throw GrainSaleException(
          message: e.message,
          statusCode: e.statusCode,
          isNetworkError: e.isNetworkError,
        );
      }
    }
    throw const GrainSaleException(
      message:
          'This grain sale is not associated with a booking slot and cannot be reviewed yet.',
    );
  }

  @override
  Future<GrainSaleItem> reviewGrainSale({
    required String accessToken,
    required String saleId,
    required double goodQuantityKg,
    required double badQuantityKg,
    bool approve = true,
    String? rejectionReason,
  }) async {
    final bookingSlotId = await _resolveBookingSlotId(
      accessToken: accessToken,
      saleId: saleId,
    );

    final item = await remoteDataSource.reviewGrainSale(
      accessToken: accessToken,
      saleId: saleId,
      bookingSlotId: bookingSlotId,
      goodQuantityKg: goodQuantityKg,
      badQuantityKg: badQuantityKg,
      approve: approve,
      rejectionReason: rejectionReason,
    );

    final farmer = _farmerCache?[item.farmerId];
    if (farmer != null) {
      return item.copyWithEnrichment(
        farmerName: farmer.name,
        farmerPhone: farmer.phone,
        farmerVillage: farmer.village,
      );
    }
    return item;
  }

  @override
  Future<GrainSaleItem> payGrainSale({
    required String accessToken,
    required String saleId,
    String? paymentReference,
  }) async {
    final item = await remoteDataSource.payGrainSale(
      accessToken: accessToken,
      saleId: saleId,
      paymentReference: paymentReference,
    );

    final farmer = _farmerCache?[item.farmerId];
    if (farmer != null) {
      return item.copyWithEnrichment(
        farmerName: farmer.name,
        farmerPhone: farmer.phone,
        farmerVillage: farmer.village,
      );
    }
    return item;
  }

  @override
  Future<GrainSaleItem> updateGrainYield({
    required String accessToken,
    required String saleId,
    required double goodMaterialKg,
    required double wastageKg,
  }) async {
    final item = await remoteDataSource.updateGrainYield(
      accessToken: accessToken,
      saleId: saleId,
      goodMaterialKg: goodMaterialKg,
      wastageKg: wastageKg,
    );

    final farmer = _farmerCache?[item.farmerId];
    if (farmer != null) {
      return item.copyWithEnrichment(
        farmerName: farmer.name,
        farmerPhone: farmer.phone,
        farmerVillage: farmer.village,
      );
    }
    return item;
  }
}
