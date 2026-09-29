import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
  static const String defaultBaseUrl = 'https://agriflow-backend-t8o4.onrender.com';
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;

  FastApiWarehouseRemoteDataSource({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

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
    try {
      final response = await client
          .get(_uri('/warehouses'), headers: _headers(accessToken))
          .timeout(const Duration(seconds: 15));

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
    } on SocketException catch (_) {
      throw const WarehouseNetworkException();
    } on TimeoutException catch (_) {
      throw const WarehouseNetworkException(
        message: 'Request timed out while loading warehouses.',
      );
    }
  }

  @override
  Future<WarehouseItem> getWarehouse({
    required String accessToken,
    required String warehouseId,
  }) async {
    try {
      final response = await client
          .get(_uri('/warehouses/$warehouseId'), headers: _headers(accessToken))
          .timeout(const Duration(seconds: 15));

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
    } on SocketException catch (_) {
      throw const WarehouseNetworkException();
    } on TimeoutException catch (_) {
      throw const WarehouseNetworkException(
        message: 'Request timed out while loading warehouse detail.',
      );
    }
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

    try {
      final response = await client
          .post(
            _uri('/warehouses'),
            headers: _headers(accessToken),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

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
    } on SocketException catch (_) {
      throw const WarehouseNetworkException();
    } on TimeoutException catch (_) {
      throw const WarehouseNetworkException(
        message: 'Request timed out while creating warehouse.',
      );
    }
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

    try {
      final response = await client
          .patch(
            _uri('/warehouses/$warehouseId'),
            headers: _headers(accessToken),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

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
    } on SocketException catch (_) {
      throw const WarehouseNetworkException();
    } on TimeoutException catch (_) {
      throw const WarehouseNetworkException(
        message: 'Request timed out while updating warehouse.',
      );
    }
  }

  @override
  Future<void> deleteWarehouse({
    required String accessToken,
    required String warehouseId,
  }) async {
    try {
      final response = await client
          .delete(_uri('/warehouses/$warehouseId'), headers: _headers(accessToken))
          .timeout(const Duration(seconds: 15));

      _parseResponse(response);
    } on SocketException catch (_) {
      throw const WarehouseNetworkException();
    } on TimeoutException catch (_) {
      throw const WarehouseNetworkException(
        message: 'Request timed out while deleting warehouse.',
      );
    }
  }

  @override
  Future<List<WarehouseInventoryItem>> getWarehouseInventory({
    required String accessToken,
    required String warehouseId,
  }) async {
    try {
      final response = await client
          .get(_uri('/warehouses/$warehouseId/inventory'), headers: _headers(accessToken))
          .timeout(const Duration(seconds: 15));

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
    } on SocketException catch (_) {
      throw const WarehouseNetworkException();
    } on TimeoutException catch (_) {
      throw const WarehouseNetworkException(
        message: 'Request timed out while loading warehouse inventory.',
      );
    }
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

    try {
      final response = await client
          .post(
            _uri('/warehouses/$warehouseId/inventory'),
            headers: _headers(accessToken),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

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
    } on SocketException catch (_) {
      throw const WarehouseNetworkException();
    } on TimeoutException catch (_) {
      throw const WarehouseNetworkException(
        message: 'Request timed out while adding warehouse inventory.',
      );
    }
  }

  @override
  Future<List<WarehouseSlotItem>> getWarehouseSlots({
    required String accessToken,
    required String warehouseId,
  }) async {
    try {
      final response = await client
          .get(_uri('/warehouses/$warehouseId/slots'), headers: _headers(accessToken))
          .timeout(const Duration(seconds: 15));

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
    } on SocketException catch (_) {
      throw const WarehouseNetworkException();
    } on TimeoutException catch (_) {
      throw const WarehouseNetworkException(
        message: 'Request timed out while loading warehouse slots.',
      );
    }
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

    try {
      final response = await client
          .get(
            _uri('/warehouse-slots', queryParams.isEmpty ? null : queryParams),
            headers: _headers(accessToken),
          )
          .timeout(const Duration(seconds: 15));

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
    } on SocketException catch (_) {
      throw const WarehouseNetworkException();
    } on TimeoutException catch (_) {
      throw const WarehouseNetworkException(
        message: 'Request timed out while listing warehouse slots.',
      );
    }
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

    try {
      final response = await client
          .post(
            _uri('/warehouse-slots'),
            headers: _headers(accessToken),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

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
    } on SocketException catch (_) {
      throw const WarehouseNetworkException();
    } on TimeoutException catch (_) {
      throw const WarehouseNetworkException(
        message: 'Request timed out while creating warehouse slot.',
      );
    }
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

    try {
      final response = await client
          .patch(
            _uri('/warehouse-slots/$slotId'),
            headers: _headers(accessToken),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

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
    } on SocketException catch (_) {
      throw const WarehouseNetworkException();
    } on TimeoutException catch (_) {
      throw const WarehouseNetworkException(
        message: 'Request timed out while updating warehouse slot.',
      );
    }
  }

  @override
  Future<void> deleteWarehouseSlot({
    required String accessToken,
    required String slotId,
  }) async {
    try {
      final response = await client
          .delete(_uri('/warehouse-slots/$slotId'), headers: _headers(accessToken))
          .timeout(const Duration(seconds: 15));

      _parseResponse(response);
    } on SocketException catch (_) {
      throw const WarehouseNetworkException();
    } on TimeoutException catch (_) {
      throw const WarehouseNetworkException(
        message: 'Request timed out while deleting warehouse slot.',
      );
    }
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
