import 'package:flutter/material.dart';
import '../../../../core/network/error_sanitizer.dart';
import '../../domain/entities/seed_inventory_item.dart';
import '../../domain/entities/seed_warehouse_brief.dart';
import '../../domain/exceptions/seeds_inventory_exception.dart';
import '../../domain/repositories/seeds_inventory_repository.dart';

/// State management controller for Seeds Inventory feature.
class SeedsInventoryController extends ChangeNotifier {
  final SeedsInventoryRepository repository;
  final String accessToken;

  SeedsInventoryController({
    required this.repository,
    required this.accessToken,
  });

  List<SeedInventoryItem> _seeds = [];
  List<SeedWarehouseBrief> _warehouses = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  String? _errorMessage;
  String? _successMessage;

  String _searchQuery = '';
  String _currentFilter = 'all'; // 'all', 'active', 'low_stock'

  // Getters
  List<SeedInventoryItem> get allSeeds => List.unmodifiable(_seeds);
  List<SeedWarehouseBrief> get warehouses => List.unmodifiable(_warehouses);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isSubmitting => _isSubmitting;
  bool get isUploadingImage => _isUploadingImage;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get searchQuery => _searchQuery;
  String get currentFilter => _currentFilter;

  int get totalSeedsCount => _seeds.where((s) => s.isActive).length;
  int get activeSeedsCount => _seeds.where((s) => s.isActive).length;
  int get inactiveSeedsCount => _seeds.where((s) => !s.isActive).length;
  int get lowStockCount => _seeds.where((s) => s.isActive && s.isLowStock).length;

  /// Reactive filtered list according to search query and active filter tab
  List<SeedInventoryItem> get filteredSeeds {
    return _seeds.where((seed) {
      // 1. Filter tab check
      switch (_currentFilter) {
        case 'all':
        case 'active':
          if (!seed.isActive) return false;
          break;
        case 'low_stock':
          if (!seed.isActive || !seed.isLowStock) return false;
          break;
        case 'inactive':
          if (seed.isActive) return false;
          break;
      }

      // 2. Search query check (name, variety, cropType, description)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = seed.name.toLowerCase().contains(query);
        final cropTypeMatch = (seed.cropType ?? '').toLowerCase().contains(query);
        final varietyMatch = (seed.variety ?? '').toLowerCase().contains(query);
        final descMatch = (seed.description ?? '').toLowerCase().contains(query);
        final warehouseMatch = seed.warehouses.any((w) => w.name.toLowerCase().contains(query));
        if (!nameMatch && !cropTypeMatch && !varietyMatch && !descMatch && !warehouseMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Load master catalog of seeds and available warehouses
  Future<void> loadSeeds({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    if (refresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        repository.getSeeds(accessToken: accessToken),
        repository.getWarehouses(accessToken: accessToken).catchError((_) => <SeedWarehouseBrief>[]),
      ]);

      _seeds = results[0] as List<SeedInventoryItem>;
      final fetchedWarehouses = results[1] as List<SeedWarehouseBrief>;
      if (fetchedWarehouses.isNotEmpty) {
        _warehouses = fetchedWarehouses;
      }
    } on SeedsInventoryException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred while loading seeds.';
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Load available warehouses from `/api/v1/warehouses`
  Future<void> loadWarehouses() async {
    try {
      final list = await repository.getWarehouses(accessToken: accessToken);
      _warehouses = list;
      notifyListeners();
    } catch (_) {
      // Non-fatal, warehouses cache preserved
    }
  }

  /// Update search query with instant local reactive filtering
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  /// Update current status filter
  void setFilter(String filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    notifyListeners();
  }

  /// Create a new seed product (Admin only)
  Future<bool> addSeed({
    required String name,
    required double pricePerKg,
    required double stockKg,
    String? cropType,
    String? variety,
    double? priceGradeA,
    double? priceGradeB,
    double? priceGradeC,
    double? maxOrderQuantityKg,
    List<String>? warehouseIds,
    String? description,
    String? imageUrl,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final created = await repository.createSeed(
        accessToken: accessToken,
        name: name,
        pricePerKg: pricePerKg,
        stockKg: stockKg,
        cropType: cropType,
        variety: variety,
        priceGradeA: priceGradeA,
        priceGradeB: priceGradeB,
        priceGradeC: priceGradeC,
        maxOrderQuantityKg: maxOrderQuantityKg,
        warehouseIds: warehouseIds,
        description: description,
        imageUrl: imageUrl,
      );

      // Prepend newly added item
      _seeds.insert(0, created);
      _successMessage = 'Seed "${created.name}" added successfully.';
      return true;
    } on SeedsInventoryForbiddenException {
      _errorMessage = 'Action forbidden: Manager role does not have permission to modify seed catalog.';
      return false;
    } on SeedsInventoryException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to add seed product.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Update an existing seed product (Admin only)
  Future<bool> updateSeed({
    required String seedId,
    String? name,
    String? cropType,
    String? variety,
    double? pricePerKg,
    double? priceGradeA,
    double? priceGradeB,
    double? priceGradeC,
    double? maxOrderQuantityKg,
    double? stockKg,
    List<String>? warehouseIds,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await repository.updateSeed(
        accessToken: accessToken,
        seedId: seedId,
        name: name,
        cropType: cropType,
        variety: variety,
        pricePerKg: pricePerKg,
        priceGradeA: priceGradeA,
        priceGradeB: priceGradeB,
        priceGradeC: priceGradeC,
        maxOrderQuantityKg: maxOrderQuantityKg,
        stockKg: stockKg,
        warehouseIds: warehouseIds,
        description: description,
        imageUrl: imageUrl,
        isActive: isActive,
      );

      final index = _seeds.indexWhere((s) => s.id == seedId);
      if (index != -1) {
        _seeds[index] = updated;
      }
      _successMessage = 'Seed "${updated.name}" updated successfully.';
      return true;
    } on SeedsInventoryForbiddenException {
      _errorMessage = 'Action forbidden: Manager role does not have permission to modify seed catalog.';
      return false;
    } on SeedsInventoryException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to update seed product.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Delete a seed product (Admin only)
  Future<bool> deleteSeed(String seedId) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await repository.deleteSeed(
        accessToken: accessToken,
        seedId: seedId,
      );

      final matchIndex = _seeds.indexWhere((s) => s.id == seedId);
      final seedName = matchIndex != -1 ? _seeds[matchIndex].name : 'Seed';
      if (matchIndex != -1) {
        _seeds[matchIndex] = _seeds[matchIndex].copyWith(isActive: false);
      }
      _successMessage = 'Seed "$seedName" deleted successfully.';
      return true;
    } on SeedsInventoryForbiddenException {
      _errorMessage = 'Action forbidden: Manager role does not have permission to modify seed catalog.';
      return false;
    } on SeedsInventoryException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to delete seed product.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Upload seed image file bytes to backend.
  ///
  /// Success returns the backend `public_url`. Failures set [errorMessage]
  /// AND rethrow the sanitized exception so the upload sheet can surface the
  /// real cause inline instead of a generic null-only message.
  Future<String?> uploadImage({
    required List<int> fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    _isUploadingImage = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final publicUrl = await repository.uploadSeedImage(
        accessToken: accessToken,
        fileBytes: fileBytes,
        fileName: fileName,
        contentType: contentType,
      );
      return publicUrl;
    } on SeedsInventoryException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } catch (_) {
      // Upload must never surface raw exception text — fixed safe message.
      const message = ErrorSanitizer.genericErrorMessage;
      _errorMessage = message;
      throw const SeedsInventoryException(message: message);
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  /// Explicitly assign warehouses to a seed
  Future<bool> assignWarehouses({
    required String seedId,
    required List<String> warehouseIds,
  }) async {
    try {
      final updatedWarehouses = await repository.assignSeedWarehouses(
        accessToken: accessToken,
        seedId: seedId,
        warehouseIds: warehouseIds,
      );

      final index = _seeds.indexWhere((s) => s.id == seedId);
      if (index != -1) {
        _seeds[index] = _seeds[index].copyWith(
          warehouses: updatedWarehouses,
          warehouseIds: updatedWarehouses.map((w) => w.id).toList(),
        );
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }
}
