import '../entities/bank_change_request_item.dart';
import '../entities/farmer_item.dart';
import '../entities/farmer_pagination.dart';

/// Abstract domain repository contract for All Farmers module.
abstract class FarmerRepository {
  Future<({List<FarmerItem> items, FarmerPagination pagination})> getFarmers({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String sort = 'created_at',
    String order = 'desc',
  });

  Future<FarmerItem> getFarmerDetail({
    required String accessToken,
    required String farmerId,
  });

  Future<FarmerItem> setFarmerApproval({
    required String accessToken,
    required String farmerId,
    required String status,
  });

  /// Partial profile update via PATCH /farmers/{farmer_id} (FEAT-04)
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
  });

  Future<FarmerItem> createFarmer({
    required String accessToken,
    required String name,
    required String phone,
    required String password,
    String? email,
    String? address,
    double? acresOfLand,
    String? cropAddress,
  });

  Future<({List<BankChangeRequestItem> items, FarmerPagination pagination})> getBankChangeRequests({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String sort = 'created_at',
    String order = 'desc',
  });

  Future<void> reviewBankChangeRequest({
    required String accessToken,
    required String requestId,
    required bool approve,
    String? adminNotes,
  });

  Future<Map<String, ({String name, String phone, String? village})>> getFarmerLookup({
    required String accessToken,
  });
}
