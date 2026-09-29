import '../entities/grain_sale_item.dart';
import '../entities/grain_sale_pagination.dart';

/// Abstract contract for Grain Sales data access.
abstract class GrainSaleRepository {
  /// Fetches paginated grain sales with optional search, status filtering, and sorting.
  Future<({List<GrainSaleItem> items, GrainSalePagination pagination})> getGrainSales({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? sort,
    String? order,
  });

  /// Logs received crop procurement intake from a farmer.
  Future<GrainSaleItem> procureCrop({
    required String accessToken,
    required String farmerId,
    required String grainType,
    required String grade,
    required double rawMaterialKg,
    required double goodMaterialKg,
    required double wastageKg,
  });

  /// Reviews crop inspection yields and moves grain sale to approved (or rejected).
  Future<GrainSaleItem> reviewGrainSale({
    required String accessToken,
    required String saleId,
    required double goodQuantityKg,
    required double badQuantityKg,
    bool approve = true,
    String? rejectionReason,
  });

  /// Authoritatively marks a grain sale as paid.
  Future<GrainSaleItem> payGrainSale({
    required String accessToken,
    required String saleId,
    String? paymentReference,
  });

  /// Corrects yield quantities (good material / wastage) for a grain sale.
  Future<GrainSaleItem> updateGrainYield({
    required String accessToken,
    required String saleId,
    required double goodMaterialKg,
    required double wastageKg,
  });

  /// Fetches farmer lookup catalog for dropdown and enrichment.
  Future<Map<String, ({String name, String phone, String? village})>> getFarmerLookup({
    required String accessToken,
  });
}
