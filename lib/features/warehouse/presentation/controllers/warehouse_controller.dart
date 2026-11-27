import 'package:flutter/material.dart';
import '../../data/repositories/warehouse_repository_impl.dart';
import '../../domain/entities/warehouse_inventory_item.dart';
import '../../domain/entities/warehouse_item.dart';
import '../../domain/entities/warehouse_slot_item.dart';
import '../../domain/exceptions/warehouse_exception.dart';
import '../../domain/repositories/warehouse_repository.dart';

/// State management controller for Warehouse Management.
class WarehouseController extends ChangeNotifier {
  final WarehouseRepository repository;
  final String accessToken;
  final bool isAdmin;

  WarehouseController({
    required this.repository,
    required this.accessToken,
    this.isAdmin = false,
  });

  List<WarehouseItem> _warehouses = [];
  WarehouseItem? _selectedWarehouse;
  List<WarehouseInventoryItem> _selectedInventory = [];
  List<WarehouseInventoryItem> _selectedBookedStock = [];
  List<WarehouseSlotItem> _selectedSlots = [];

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isSubmitting = false;
  bool _isLoadingDetails = false;
  String? _errorMessage;
  String? _successMessage;

  String _searchQuery = '';
  String _currentFilter = 'all'; // 'all', 'active', 'inactive', 'near_full'

  // Getters
  List<WarehouseItem> get allWarehouses => List.unmodifiable(_warehouses);
  List<WarehouseItem> get warehouses => allWarehouses;
  WarehouseItem? get selectedWarehouse => _selectedWarehouse;
  List<WarehouseInventoryItem> get selectedInventory => List.unmodifiable(_selectedInventory);
  List<WarehouseInventoryItem> get selectedBookedStock => List.unmodifiable(_selectedBookedStock);
  List<WarehouseSlotItem> get selectedSlots => List.unmodifiable(_selectedSlots);

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get searchQuery => _searchQuery;
  String get currentFilter => _currentFilter;

  int get totalWarehousesCount => _warehouses.length;
  int get activeWarehousesCount => _warehouses.where((w) => w.isActive).length;
  int get inactiveWarehousesCount => _warehouses.where((w) => !w.isActive).length;
  int get nearFullCount => _warehouses.where((w) => w.isNearCapacity || w.isOverCapacity).length;

  double get totalCapacityQtl =>
      _warehouses.fold<double>(0.0, (sum, w) => sum + w.totalCapacityQtl);
  double get totalLoadQtl =>
      _warehouses.fold<double>(0.0, (sum, w) => sum + w.currentLoadQtl);

  double get averageOccupancyPercent {
    if (_warehouses.isEmpty) return 0.0;
    final totalCap = _warehouses.fold<double>(0.0, (sum, w) => sum + w.totalCapacityKg);
    if (totalCap <= 0.0) return 0.0;
    final totalLoad = _warehouses.fold<double>(0.0, (sum, w) => sum + w.currentLoadKg);
    return (totalLoad / totalCap) * 100.0;
  }

  /// Reactive filtered list according to search query and active filter tab
  List<WarehouseItem> get filteredWarehouses {
    return _warehouses.where((warehouse) {
      if (_currentFilter == 'active' && !warehouse.isActive) {
        return false;
      }
      if (_currentFilter == 'inactive' && warehouse.isActive) {
        return false;
      }
      if (_currentFilter == 'near_full' &&
          !warehouse.isNearCapacity &&
          !warehouse.isOverCapacity) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = warehouse.name.toLowerCase().contains(query);
        final addressMatch = warehouse.address.toLowerCase().contains(query);
        final locationMatch = (warehouse.location ?? '').toLowerCase().contains(query);
        if (!nameMatch && !addressMatch && !locationMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Load master list of warehouses
  Future<void> loadWarehouses({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    if (refresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await repository.getWarehouses(accessToken: accessToken);
      _warehouses = fetched;

      // If a warehouse was previously selected, refresh its local reference
      if (_selectedWarehouse != null) {
        final updated = _warehouses.where((w) => w.id == _selectedWarehouse!.id);
        if (updated.isNotEmpty) {
          _selectedWarehouse = updated.first;
        }
      }
    } on WarehouseException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred while loading warehouses.';
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Select a warehouse and load its inventory, booked stock, and slots
  Future<void> selectWarehouse(WarehouseItem warehouse) async {
    _selectedWarehouse = warehouse;
    _selectedInventory = [];
    _selectedBookedStock = [];
    _selectedSlots = [];
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final repo = repository;
      final results = await Future.wait([
        repository.getWarehouseInventory(
          accessToken: accessToken,
          warehouseId: warehouse.id,
        ),
        repository.getWarehouseSlots(
          accessToken: accessToken,
          warehouseId: warehouse.id,
        ).catchError((_) => <WarehouseSlotItem>[]),
        repository.getWarehouse(
          accessToken: accessToken,
          warehouseId: warehouse.id,
        ).catchError((_) => warehouse),
        if (repo is WarehouseRepositoryImpl)
          repo.getBookedStockForWarehouse(
            accessToken: accessToken,
            warehouseId: warehouse.id,
          )
        else
          Future.value(<WarehouseInventoryItem>[]),
      ]);

      _selectedInventory = results[0] as List<WarehouseInventoryItem>;
      _selectedSlots = results[1] as List<WarehouseSlotItem>;
      _selectedWarehouse = results[2] as WarehouseItem;
      _selectedBookedStock = results[3] as List<WarehouseInventoryItem>;

      // Update in main list as well
      final idx = _warehouses.indexWhere((w) => w.id == warehouse.id);
      if (idx != -1) {
        _warehouses[idx] = _selectedWarehouse!;
      }
    } on WarehouseException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load warehouse inventory details.';
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  void clearSelectedWarehouse() {
    _selectedWarehouse = null;
    _selectedInventory = [];
    _selectedBookedStock = [];
    _selectedSlots = [];
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Create warehouse (Admin only)
  Future<bool> createWarehouse({
    required String name,
    required String address,
    required double totalCapacityKg,
    String? location,
    String? contactNumber,
    String? managerId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final created = await repository.createWarehouse(
        accessToken: accessToken,
        name: name,
        address: address,
        totalCapacityKg: totalCapacityKg,
        location: location,
        contactNumber: contactNumber,
        managerId: managerId,
      );

      _warehouses.insert(0, created);
      _successMessage = 'Warehouse "${created.name}" created successfully.';
      return true;
    } on WarehouseForbiddenException catch (e) {
      _errorMessage = e.message;
      return false;
    } on WarehouseException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to create warehouse.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Update warehouse (Admin only)
  Future<bool> updateWarehouse({
    required String warehouseId,
    String? name,
    String? address,
    double? totalCapacityKg,
    String? location,
    String? contactNumber,
    String? managerId,
    bool? isActive,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await repository.updateWarehouse(
        accessToken: accessToken,
        warehouseId: warehouseId,
        name: name,
        address: address,
        totalCapacityKg: totalCapacityKg,
        location: location,
        contactNumber: contactNumber,
        managerId: managerId,
        isActive: isActive,
      );

      final index = _warehouses.indexWhere((w) => w.id == warehouseId);
      if (index != -1) {
        _warehouses[index] = updated;
      }
      if (_selectedWarehouse?.id == warehouseId) {
        _selectedWarehouse = updated;
      }

      _successMessage = 'Warehouse "${updated.name}" updated successfully.';
      return true;
    } on WarehouseForbiddenException catch (e) {
      _errorMessage = e.message;
      return false;
    } on WarehouseException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to update warehouse.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Delete warehouse (Admin only)
  Future<bool> deleteWarehouse(String warehouseId) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await repository.deleteWarehouse(
        accessToken: accessToken,
        warehouseId: warehouseId,
      );

      _warehouses.removeWhere((w) => w.id == warehouseId);
      if (_selectedWarehouse?.id == warehouseId) {
        _selectedWarehouse = null;
        _selectedInventory = [];
        _selectedSlots = [];
      }

      _successMessage = 'Warehouse deleted successfully.';
      return true;
    } on WarehouseForbiddenException catch (e) {
      _errorMessage = e.message;
      return false;
    } on WarehouseException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to delete warehouse.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Add grain inventory stock intake
  Future<bool> addInventory({
    required String warehouseId,
    required String grainType,
    required double quantityKg,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final added = await repository.addWarehouseInventory(
        accessToken: accessToken,
        warehouseId: warehouseId,
        grainType: grainType,
        quantityKg: quantityKg,
      );

      // Refresh inventory list and updated warehouse load
      final updatedInv = await repository.getWarehouseInventory(
        accessToken: accessToken,
        warehouseId: warehouseId,
      );
      _selectedInventory = updatedInv;

      // Refresh warehouse load
      final refreshedWh = await repository.getWarehouse(
        accessToken: accessToken,
        warehouseId: warehouseId,
      );
      _selectedWarehouse = refreshedWh;
      final idx = _warehouses.indexWhere((w) => w.id == warehouseId);
      if (idx != -1) {
        _warehouses[idx] = refreshedWh;
      }

      _successMessage = 'Added ${(added.quantityKg / 100).toStringAsFixed(1)} Qtl of ${added.grainType} successfully.';
      return true;
    } on WarehouseException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to add grain inventory.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Create booking slot
  Future<bool> createSlot({
    required String warehouseId,
    required String slotDate,
    required String startTime,
    required String endTime,
    required double capacityKg,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final created = await repository.createWarehouseSlot(
        accessToken: accessToken,
        warehouseId: warehouseId,
        slotDate: slotDate,
        startTime: startTime,
        endTime: endTime,
        capacityKg: capacityKg,
      );

      _selectedSlots.insert(0, created);
      _successMessage = 'Booking slot created successfully.';
      return true;
    } on WarehouseException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to create booking slot.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Cancel booking slot
  Future<bool> cancelSlot(String slotId) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await repository.updateWarehouseSlot(
        accessToken: accessToken,
        slotId: slotId,
        status: 'cancelled',
      );

      final index = _selectedSlots.indexWhere((s) => s.id == slotId);
      if (index != -1) {
        _selectedSlots[index] = updated;
      }

      _successMessage = 'Booking slot cancelled successfully.';
      return true;
    } on WarehouseException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to cancel booking slot.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Delete booking slot
  Future<bool> deleteSlot(String slotId) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await repository.deleteWarehouseSlot(
        accessToken: accessToken,
        slotId: slotId,
      );

      _selectedSlots.removeWhere((s) => s.id == slotId);
      _successMessage = 'Booking slot deleted.';
      return true;
    } on WarehouseException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to delete booking slot.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
