/// Clean repository contracts for the AgriFlow Admin & Manager mobile app.
///
/// =========================================================================
/// BACKEND CONTRACT POLICY:
/// Backend/FastAPI APIs and PostgreSQL database are strictly handled by Syed.
/// All frontend repositories will consume these contracts when Syed supplies
/// the production endpoints.
/// =========================================================================
library;

abstract class IAuthRepository {
  /// Verified FastAPI Contract: POST /api/v1/auth/login
  Future<dynamic> login({required String phone, required String password});

  /// Verified FastAPI Contract: POST /api/v1/auth/logout
  Future<void> logout();

  /// Verified FastAPI Contract: GET /api/v1/users/me
  Future<dynamic> getCurrentSession();

  /// Verified FastAPI Contract: POST /api/v1/auth/refresh
  Future<dynamic> refreshToken(String refreshToken);

  /// Verified FastAPI Contract: POST /api/v1/auth/forgot-password/send-otp
  Future<void> requestPasswordReset(String phone);

  /// Verified FastAPI Contract: POST /api/v1/auth/forgot-password/reset
  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  });
}


abstract class IDashboardRepository {
  /// Backend API required — to be supplied by Syed.
  Future<dynamic> getDashboardSummary({required String role, String? managerId});

  /// Backend API required — to be supplied by Syed.
  Future<List<dynamic>> getRecentActivities({int limit = 5});
}

abstract class ISeedPurchaseRepository {
  /// Backend API required — to be supplied by Syed.
  Future<List<dynamic>> getSeedPurchaseRequests({String? statusFilter, String? search});

  /// Backend API required — to be supplied by Syed.
  Future<dynamic> getRequestDetails(String requestId);

  /// Backend API required — to be supplied by Syed.
  Future<void> approveRequest({required String requestId, String? notes});

  /// Backend API required — to be supplied by Syed.
  Future<void> rejectRequest({required String requestId, required String reason});
}

abstract class IBookingSlotsRepository {
  /// Backend API required — to be supplied by Syed.
  Future<List<dynamic>> getBookingSlots({required DateTime date, String? village});

  /// Backend API required — to be supplied by Syed.
  Future<dynamic> createSlot({
    required DateTime date,
    required String startTime,
    required String endTime,
    required int capacity,
    required String officer,
    required String village,
  });

  /// Backend API required — to be supplied by Syed.
  Future<void> cancelSlot(String slotId);

  /// Backend API required — to be supplied by Syed.
  Future<void> sendSlotReminder(String slotId);
}

abstract class IFarmVisitsRepository {
  /// Backend API required — to be supplied by Syed.
  Future<List<dynamic>> getFarmVisits({String? statusFilter, String? search});

  /// Backend API required — to be supplied by Syed.
  Future<dynamic> getVisitDetails(String visitId);

  /// Backend API required — to be supplied by Syed.
  Future<dynamic> scheduleVisit({
    required String farmerName,
    required String cropAcreage,
    required DateTime dateTime,
    required String fieldOfficer,
    required String village,
  });

  /// Backend API required — to be supplied by Syed.
  Future<void> updateVisitStatus({
    required String visitId,
    required String status,
    String? cropPhotoPath,
    String? reportNotes,
  });
}

abstract class IGrainSalesRepository {
  /// Backend API required — to be supplied by Syed.
  Future<List<dynamic>> getGrainSales({String? statusFilter, String? search});

  /// Backend API required — to be supplied by Syed.
  Future<dynamic> logReceivedCrop({
    required String farmerId,
    required String cropType,
    required String grade,
    required double rawQtyQtl,
    required double goodQtyQtl,
    required double wastageQtyQtl,
  });

  /// Backend API required — to be supplied by Syed.
  Future<void> markSalePaid({required String saleId, String? paymentRef});
}

abstract class ISeedsInventoryRepository {
  /// Backend API required — to be supplied by Syed.
  Future<List<dynamic>> getSeedInventory({String? search});

  /// Backend API required — to be supplied by Syed.
  Future<void> adjustStock({required String seedId, required int deltaQuantity});

  /// Backend API required — to be supplied by Syed.
  Future<dynamic> addSeedVariety({
    required String name,
    required String variety,
    required double pricePerKg,
    required double stockQtl,
    required List<String> warehouseIds,
    String? description,
    String? imagePath,
  });
}

abstract class IWarehouseRepository {
  /// Backend API required — to be supplied by Syed.
  Future<List<dynamic>> getWarehouses();

  /// Backend API required — to be supplied by Syed.
  Future<dynamic> getWarehouseInventory(String warehouseId);

  /// Backend API required — to be supplied by Syed.
  Future<void> addInventoryStock({required String warehouseId, required String grainType, required double quantityKg});

  /// Backend API required — to be supplied by Syed.
  Future<void> addWarehouseSlot({
    required String warehouseId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required double capacityKg,
  });
}

abstract class IBillingRepository {
  /// Backend API required — to be supplied by Syed.
  Future<List<dynamic>> getInvoices({String? statusFilter, String? search});

  /// Backend API required — to be supplied by Syed.
  Future<dynamic> logTransaction({
    required String customerId,
    required String customerName,
    required String txType,
    required String direction,
    required double amount,
    required String paymentMethod,
    String? referenceId,
    String? remarks,
  });
}

abstract class IMarketRatesRepository {
  /// GET /api/v1/market-rates (authenticated; falls back to
  /// GET /api/v1/public/market-rates — identical payload).
  Future<List<dynamic>> getMarketRates({required String accessToken});

  /// POST /api/v1/market-rates — one grade per call.
  /// No PATCH/PUT/DELETE exists in the verified OpenAPI.
  Future<void> setRate({
    required String accessToken,
    required String cropType,
    required String grade,
    required double pricePerKg,
    required String effectiveDate,
  });
}

abstract class IFarmersRepository {
  /// Backend API required — to be supplied by Syed.
  Future<List<dynamic>> getFarmers({String? statusFilter, String? search});

  /// Backend API required — to be supplied by Syed.
  Future<dynamic> getFarmerProfile(String farmerId);

  /// Backend API required — to be supplied by Syed.
  Future<dynamic> registerFarmer({
    required String name,
    required String phone,
    String? email,
    double? landAcres,
    String? address,
  });

  /// Backend API required — to be supplied by Syed.
  Future<void> approveFarmerKYC({required String farmerId, required String status});

  /// Backend API required — to be supplied by Syed.
  Future<void> deleteFarmer(String farmerId);
}

abstract class IManagersRepository {
  /// Backend API required — to be supplied by Syed.
  Future<List<dynamic>> getManagers();

  /// Backend API required — to be supplied by Syed.
  Future<dynamic> createManager({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String region,
    required String department,
  });

  /// Backend API required — to be supplied by Syed.
  Future<void> updateManagerStatus(String managerId, String status);

  /// Backend API required — to be supplied by Syed.
  Future<void> resetManagerPassword(String managerId, String newPassword);
}

abstract class IReportsRepository {
  /// Backend API required — to be supplied by Syed.
  Future<dynamic> getMonthlyReport(String monthIso);

  /// Backend API required — to be supplied by Syed.
  Future<List<int>> downloadReportPdf(String monthIso);
}

abstract class IEventLogsRepository {
  /// Backend API required — to be supplied by Syed.
  Future<List<dynamic>> getAuditLogs({int page = 1, int limit = 50});
}

abstract class ICreditsRepository {
  /// Backend API required — to be supplied by Syed.
  Future<List<dynamic>> getCreditLedger({String? search});

  /// Backend API required — to be supplied by Syed.
  Future<void> addCreditEntry({
    required String farmerId,
    required double amount,
    required String direction,
    required String description,
  });
}

abstract class ICacheRepository {
  /// Backend API required — to be supplied by Syed.
  Future<List<dynamic>> getCacheKeys();

  /// Backend API required — to be supplied by Syed.
  Future<void> clearCacheKeys(List<String> keys);

  /// Backend API required — to be supplied by Syed.
  Future<void> clearAllCache();
}
