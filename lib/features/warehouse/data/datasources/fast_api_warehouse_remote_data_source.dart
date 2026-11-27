import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:agriflow_admin/core/network/api_client.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import '../../domain/entities/warehouse_inventory_item.dart';
import '../../domain/entities/warehouse_item.dart';
import '../../domain/entities/warehouse_slot_item.dart';
import '../../domain/exceptions/warehouse_exception.dart';

/// Abstract remote data source contract for Warehouse management.
abstract class WarehouseRemoteDataSource {
  Future<List<WarehouseItem>> getWarehouses({required String accessToken});

  Future<WarehouseItem> getWarehouse({
    required String accessToken,
    required String warehouseId,
  });

  Future<WarehouseItem> createWarehouse({
    required String accessToken,
    required String name,
    required String address,
    required double totalCapacityKg,
    String? location,
    String? contactNumber,
    String? managerId,
  });

  Future<WarehouseItem> updateWarehouse({
    required String accessToken,
    required String warehouseId,
    String? name,
    String? address,
    double? totalCapacityKg,
    String? location,
    String? contactNumber,
    String? managerId,
    bool? isActive,
  });

  Future<void> deleteWarehouse({
    required String accessToken,
    required String warehouseId,
  });

  Future<List<WarehouseInventoryItem>> getWarehouseInventory({
    required String accessToken,
    required String warehouseId,
  });

  Future<WarehouseInventoryItem> addWarehouseInventory({
    required String accessToken,
    required String warehouseId,
    required String grainType,
    required double quantityKg,
  });

  Future<List<WarehouseSlotItem>> getWarehouseSlots({
    required String accessToken,
    required String warehouseId,
  });

  Future<List<WarehouseSlotItem>> listWarehouseSlots({
    required String accessToken,
    String? warehouseId,
    String? date,
  });

  Future<WarehouseSlotItem> createWarehouseSlot({
    required String accessToken,
    required String warehouseId,
    required String slotDate,
    required String startTime,
    required String endTime,
    required double capacityKg,
  });

  Future<WarehouseSlotItem> updateWarehouseSlot({
    required String accessToken,
    required String slotId,
    String? status,
    double? capacityKg,
  });

  Future<void> deleteWarehouseSlot({
    required String accessToken,
    required String slotId,
  });
}

/// FastAPI implementation calling `/api/v1/warehouses` and `/api/v1/warehouse-slots`.
class FastApiWarehouseRemoteDataSource implements WarehouseRemoteDataSource {
  static const String defaultBaseUrl = ApiClient.defaultBaseUrl;
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;
  final ApiClient? apiClient;

  FastApiWarehouseRemoteDataSource({
    String? baseUrl,
    http.Client? client,
    this.apiClient,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

  Future<http.Response> _send(
    String method,
    String path, {
    required String accessToken,
    Map<String, dynamic>? queryParams,
    Object? body,
    String timeoutMessage = 'Request timed out.',
  }) async {
    final uri = _uri(path, queryParams);
    const timeout = Duration(seconds: 15);
    try {
      final authClient = apiClient;
      if (authClient != null) {
        switch (method) {
          case 'GET':
            return await authClient.get(uri, timeout: timeout);
          case 'POST':
            return await authClient.post(uri, body: body, timeout: timeout);
          case 'PATCH':
            return await authClient.patch(uri, body: body, timeout: timeout);
          case 'DELETE':
            return await authClient.delete(uri, body: body, timeout: timeout);
        }
      }

      final headers = _headers(accessToken);
      switch (method) {
        case 'GET':
          return await client.get(uri, headers: headers).timeout(timeout);
        case 'POST':
          return await client
              .post(uri, headers: headers, body: body)
              .timeout(timeout);
        case 'PATCH':
          return await client
              .patch(uri, headers: headers, body: body)
              .timeout(timeout);
        case 'DELETE':
          return await client
              .delete(uri, headers: headers, body: body)
              .timeout(timeout);
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
    } on AuthException catch (e) {
      if (e.statusCode == 401 || e.errorCode == 'SESSION_EXPIRED') {
        throw WarehouseUnauthorizedException(message: e.message);
      }
      if (e.isNetworkError) {
        throw WarehouseNetworkException(message: e.message);
      }
      throw WarehouseException(message: e.message, statusCode: e.statusCode);
    } on SocketException catch (_) {
      throw const WarehouseNetworkException();
    } on http.ClientException catch (_) {
      throw const WarehouseNetworkException();
    } on TimeoutException catch (_) {
      throw WarehouseNetworkException(message: timeoutMessage);
    }
  }

  Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final urlString = '$cleanedBase$apiPrefix$path';
    final baseUri = Uri.parse(urlString);
    if (queryParams != null && queryParams.isNotEmpty) {
      final sanitizedParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          sanitizedParams[key] = value.toString();
        }
      });
      return baseUri.replace(queryParameters: sanitizedParams);
    }
    return baseUri;
  }

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<WarehouseItem>> getWarehouses({required String accessToken}) async {
    final response = await _send(
      'GET',
      '/warehouses',
      accessToken: accessToken,
      timeoutMessage: 'Request timed out while loading warehouses.',
    );

    final json = _parseResponse(response);
    List<dynamic> itemsList = [];
    if (json is Map<String, dynamic>) {
      if (json['data'] is List) {
        itemsList = json['data'] as List<dynamic>;
      } else if (json['data'] is Map && json['data']['items'] is List) {
        itemsList = json['data']['items'] as List<dynamic>;
      }
    } else if (json is List) {
      itemsList = json;
    }

    return itemsList
        .whereType<Map<String, dynamic>>()
        .map((m) => WarehouseItem.fromJson(m))
        .toList();
  }

  @override
  Future<WarehouseItem> getWarehouse({
    required String accessToken,
    required String warehouseId,
  }) async {
    final response = await _send(
      'GET',
      '/warehouses/$warehouseId',
      accessToken: accessToken,
      timeoutMessage: 'Request timed out while loading warehouse detail.',
    );

    final json = _parseResponse(response);
    Map<String, dynamic> dataMap;
    if (json is Map<String, dynamic> && json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      dataMap = json['data'] as Map<String, dynamic>;
    } else if (json is Map<String, dynamic>) {
      dataMap = json;
    } else {
      throw const WarehouseException(message: 'Invalid warehouse response structure.');
    }

    return WarehouseItem.fromJson(dataMap);
  }

  @override
  Future<WarehouseItem> createWarehouse({
    required String accessToken,
    required String name,
    required String address,
    required double totalCapacityKg,
    String? location,
    String? contactNumber,
    String? managerId,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'address': address,
      'total_capacity_kg': totalCapacityKg,
      if (location != null && location.isNotEmpty) 'location': location,
      if (contactNumber != null && contactNumber.isNotEmpty) 'contact_number': contactNumber,
      if (managerId != null && managerId.isNotEmpty) 'manager_id': managerId,
    };

    final response = await _send(
      'POST',
      '/warehouses',
      accessToken: accessToken,
      body: jsonEncode(payload),
      timeoutMessage: 'Request timed out while creating warehouse.',
    );

    final json = _parseResponse(response);
    Map<String, dynamic> dataMap;
    if (json is Map<String, dynamic> && json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      dataMap = json['data'] as Map<String, dynamic>;
    } else if (json is Map<String, dynamic>) {
      dataMap = json;
    } else {
      throw const WarehouseException(message: 'Invalid create warehouse response.');
    }

    return WarehouseItem.fromJson(dataMap);
  }

  @override
  Future<WarehouseItem> updateWarehouse({
    required String accessToken,
    required String warehouseId,
    String? name,
    String? address,
    double? totalCapacityKg,
    String? location,
    String? contactNumber,
    String? managerId,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (address != null) payload['address'] = address;
    if (totalCapacityKg != null) payload['total_capacity_kg'] = totalCapacityKg;
    if (location != null) payload['location'] = location;
    if (contactNumber != null) payload['contact_number'] = contactNumber;
    if (managerId != null) payload['manager_id'] = managerId;
    if (isActive != null) payload['is_active'] = isActive;

    final response = await _send(
      'PATCH',
      '/warehouses/$warehouseId',
      accessToken: accessToken,
      body: jsonEncode(payload),
      timeoutMessage: 'Request timed out while updating warehouse.',
    );

    final json = _parseResponse(response);
    Map<String, dynamic> dataMap;
    if (json is Map<String, dynamic> && json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      dataMap = json['data'] as Map<String, dynamic>;
    } else if (json is Map<String, dynamic>) {
      dataMap = json;
    } else {
      throw const WarehouseException(message: 'Invalid update warehouse response.');
    }

    return WarehouseItem.fromJson(dataMap);
  }

  @override
  Future<void> deleteWarehouse({
    required String accessToken,
    required String warehouseId,
  }) async {
    final response = await _send(
      'DELETE',
      '/warehouses/$warehouseId',
      accessToken: accessToken,
      timeoutMessage: 'Request timed out while deleting warehouse.',
    );

    _parseResponse(response);
  }

  @override
  Future<List<WarehouseInventoryItem>> getWarehouseInventory({
    required String accessToken,
    required String warehouseId,
  }) async {
    final response = await _send(
      'GET',
      '/warehouses/$warehouseId/inventory',
      accessToken: accessToken,
      timeoutMessage: 'Request timed out while loading warehouse inventory.',
    );

    final json = _parseResponse(response);
    List<dynamic> itemsList = [];
    if (json is Map<String, dynamic>) {
      if (json['data'] is List) {
        itemsList = json['data'] as List<dynamic>;
      }
    } else if (json is List) {
      itemsList = json;
    }

    return itemsList
        .whereType<Map<String, dynamic>>()
        .map((m) => WarehouseInventoryItem.fromJson(m))
        .toList();
  }

  /// Queries active farmer bookings targeting [warehouseId] and summarizes
  /// booked grain quantities by crop type for warehouses whose `currentLoadKg`
  /// reflects farmer bookings not yet logged in manual inventory.
  Future<List<WarehouseInventoryItem>> getBookedStockForWarehouse({
    required String accessToken,
    required String warehouseId,
  }) async {
    final totalsByGrain = <String, double>{};
    var page = 1;
    var totalPages = 1;
    try {
      while (page <= totalPages && page <= 5) {
        final response = await _send(
          'GET',
          '/bookings',
          accessToken: accessToken,
          queryParams: {'page': page.toString(), 'page_size': '100'},
          timeoutMessage: 'Request timed out while loading booked warehouse grain.',
        );
        final json = _parseResponse(response);
        if (json is! Map<String, dynamic>) break;
        final data = json['data'] as List<dynamic>? ?? const [];
        for (final raw in data) {
          if (raw is! Map<String, dynamic>) continue;
          if ((raw['warehouse_id'] ?? '').toString() != warehouseId) continue;
          final status = (raw['status'] ?? '').toString().toLowerCase();
          if (status == 'cancelled') continue;
          final grain = (raw['grain_type'] ?? 'Grain').toString().trim();
          final qty = double.tryParse((raw['quantity_kg'] ?? '0').toString()) ?? 0.0;
          if (qty <= 0) continue;
          final key = grain.isEmpty ? 'Grain' : grain;
          totalsByGrain[key] = (totalsByGrain[key] ?? 0.0) + qty;
        }
        final pagination = json['pagination'];
        if (pagination is Map<String, dynamic>) {
          totalPages = int.tryParse((pagination['total_pages'] ?? 1).toString()) ?? 1;
        } else {
          break;
        }
        page++;
      }
    } catch (_) {
      return const [];
    }

    return totalsByGrain.entries
        .map(
          (e) => WarehouseInventoryItem(
            id: 'booked-${e.key.toLowerCase()}',
            warehouseId: warehouseId,
            grainType: e.key,
            quantityKg: e.value,
          ),
        )
        .toList();
  }

  @override
  Future<WarehouseInventoryItem> addWarehouseInventory({
    required String accessToken,
    required String warehouseId,
    required String grainType,
    required double quantityKg,
  }) async {
    final payload = <String, dynamic>{
      'grain_type': grainType,
      'quantity_kg': quantityKg,
    };

    final response = await _send(
      'POST',
      '/warehouses/$warehouseId/inventory',
      accessToken: accessToken,
      body: jsonEncode(payload),
      timeoutMessage: 'Request timed out while adding warehouse inventory.',
    );

    final json = _parseResponse(response);
    Map<String, dynamic> dataMap;
    if (json is Map<String, dynamic> && json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      dataMap = json['data'] as Map<String, dynamic>;
    } else if (json is Map<String, dynamic>) {
      dataMap = json;
    } else {
      throw const WarehouseException(message: 'Invalid add inventory response.');
    }

    return WarehouseInventoryItem.fromJson(dataMap);
  }

  @override
  Future<List<WarehouseSlotItem>> getWarehouseSlots({
    required String accessToken,
    required String warehouseId,
  }) async {
    final response = await _send(
      'GET',
      '/warehouses/$warehouseId/slots',
      accessToken: accessToken,
      timeoutMessage: 'Request timed out while loading warehouse slots.',
    );

    final json = _parseResponse(response);
    List<dynamic> itemsList = [];
    if (json is Map<String, dynamic>) {
      if (json['data'] is List) {
        itemsList = json['data'] as List<dynamic>;
      }
    } else if (json is List) {
      itemsList = json;
    }

    return itemsList
        .whereType<Map<String, dynamic>>()
        .map((m) => WarehouseSlotItem.fromJson(m))
        .toList();
  }

  @override
  Future<List<WarehouseSlotItem>> listWarehouseSlots({
    required String accessToken,
    String? warehouseId,
    String? date,
  }) async {
    final queryParams = <String, String>{};
    if (warehouseId != null) queryParams['warehouse_id'] = warehouseId;
    if (date != null) queryParams['date'] = date;

    final response = await _send(
      'GET',
      '/warehouse-slots',
      accessToken: accessToken,
      queryParams: queryParams.isEmpty ? null : queryParams,
      timeoutMessage: 'Request timed out while listing warehouse slots.',
    );

    final json = _parseResponse(response);
    List<dynamic> itemsList = [];
    if (json is Map<String, dynamic>) {
      if (json['data'] is List) {
        itemsList = json['data'] as List<dynamic>;
      }
    } else if (json is List) {
      itemsList = json;
    }

    return itemsList
        .whereType<Map<String, dynamic>>()
        .map((m) => WarehouseSlotItem.fromJson(m))
        .toList();
  }

  @override
  Future<WarehouseSlotItem> createWarehouseSlot({
    required String accessToken,
    required String warehouseId,
    required String slotDate,
    required String startTime,
    required String endTime,
    required double capacityKg,
  }) async {
    final payload = <String, dynamic>{
      'warehouse_id': warehouseId,
      'slot_date': slotDate,
      'start_time': startTime,
      'end_time': endTime,
      'capacity_kg': capacityKg,
    };

    final response = await _send(
      'POST',
      '/warehouse-slots',
      accessToken: accessToken,
      body: jsonEncode(payload),
      timeoutMessage: 'Request timed out while creating warehouse slot.',
    );

    final json = _parseResponse(response);
    Map<String, dynamic> dataMap;
    if (json is Map<String, dynamic> && json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      dataMap = json['data'] as Map<String, dynamic>;
    } else if (json is Map<String, dynamic>) {
      dataMap = json;
    } else {
      throw const WarehouseException(message: 'Invalid create slot response.');
    }

    return WarehouseSlotItem.fromJson(dataMap);
  }

  @override
  Future<WarehouseSlotItem> updateWarehouseSlot({
    required String accessToken,
    required String slotId,
    String? status,
    double? capacityKg,
  }) async {
    final payload = <String, dynamic>{};
    if (status != null) payload['status'] = status;
    if (capacityKg != null) payload['capacity_kg'] = capacityKg;

    final response = await _send(
      'PATCH',
      '/warehouse-slots/$slotId',
      accessToken: accessToken,
      body: jsonEncode(payload),
      timeoutMessage: 'Request timed out while updating warehouse slot.',
    );

    final json = _parseResponse(response);
    Map<String, dynamic> dataMap;
    if (json is Map<String, dynamic> && json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      dataMap = json['data'] as Map<String, dynamic>;
    } else if (json is Map<String, dynamic>) {
      dataMap = json;
    } else {
      throw const WarehouseException(message: 'Invalid update slot response.');
    }

    return WarehouseSlotItem.fromJson(dataMap);
  }

  @override
  Future<void> deleteWarehouseSlot({
    required String accessToken,
    required String slotId,
  }) async {
    final response = await _send(
      'DELETE',
      '/warehouse-slots/$slotId',
      accessToken: accessToken,
      timeoutMessage: 'Request timed out while deleting warehouse slot.',
    );

    _parseResponse(response);
  }

  dynamic _parseResponse(http.Response response) {
    if (response.statusCode == 204) {
      return {'success': true};
    }

    dynamic json;
    try {
      json = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true};
      }
      _handleHttpError(response.statusCode, 'Malformed or unexpected response from server');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    String message = 'Warehouse operation failed (${response.statusCode})';
    if (json is Map<String, dynamic>) {
      if (json.containsKey('detail')) {
        final detail = json['detail'];
        if (detail is String) {
          message = detail;
        } else if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first.containsKey('msg')) {
            message = first['msg'].toString().replaceFirst('Value error, ', '');
          }
        }
      } else if (json.containsKey('error') && json['error'] is Map) {
        message = json['error']['message'] as String? ?? message;
      } else if (json.containsKey('message')) {
        message = json['message'] as String? ?? message;
      }
    }

    _handleHttpError(response.statusCode, message);
  }

  Never _handleHttpError(int statusCode, String message) {
    switch (statusCode) {
      case 401:
        throw WarehouseUnauthorizedException(message: message);
      case 403:
        throw WarehouseForbiddenException(message: message);
      case 404:
        throw WarehouseNotFoundException(message: message);
      case 409:
        throw WarehouseConflictException(message: message);
      case 422:
        throw WarehouseValidationException(message: message);
      default:
        if (statusCode >= 500) {
          throw WarehouseServerException(message: message);
        }
        throw WarehouseException(
          message: message,
          statusCode: statusCode,
        );
    }
  }
}
