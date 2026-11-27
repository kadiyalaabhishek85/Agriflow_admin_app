import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:agriflow_admin/core/network/api_client.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/network/error_sanitizer.dart';
import '../../domain/entities/seed_inventory_item.dart';
import '../../domain/entities/seed_warehouse_brief.dart';
import '../../domain/exceptions/seeds_inventory_exception.dart';

/// Abstract remote data source contract for Seeds Inventory.
abstract class SeedsInventoryRemoteDataSource {
  Future<List<SeedInventoryItem>> getSeeds({required String accessToken});

  Future<SeedInventoryItem> getSeed({
    required String accessToken,
    required String seedId,
  });

  Future<SeedInventoryItem> createSeed({
    required String accessToken,
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
  });

  Future<SeedInventoryItem> updateSeed({
    required String accessToken,
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
  });

  Future<void> deleteSeed({
    required String accessToken,
    required String seedId,
  });

  Future<List<SeedWarehouseBrief>> getWarehouses({required String accessToken});

  Future<List<SeedWarehouseBrief>> getSeedWarehouses({
    required String accessToken,
    required String seedId,
  });

  Future<List<SeedWarehouseBrief>> assignSeedWarehouses({
    required String accessToken,
    required String seedId,
    required List<String> warehouseIds,
  });

  Future<void> removeSeedWarehouse({
    required String accessToken,
    required String seedId,
    required String warehouseId,
  });

  Future<String> uploadSeedImage({
    required String accessToken,
    required List<int> fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  });
}

/// FastAPI implementation calling `/api/v1/seeds`, `/api/v1/warehouses`, and `/api/v1/uploads`.
class FastApiSeedsInventoryRemoteDataSource implements SeedsInventoryRemoteDataSource {
  static const String defaultBaseUrl = ApiClient.defaultBaseUrl;
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;
  final ApiClient? apiClient;

  FastApiSeedsInventoryRemoteDataSource({
    String? baseUrl,
    http.Client? client,
    this.apiClient,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl$apiPrefix$path');

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _send(
    String method,
    String path, {
    required String accessToken,
    Object? body,
    Duration timeout = const Duration(seconds: 15),
    required String timeoutMessage,
  }) async {
    try {
      final authClient = apiClient;
      if (authClient != null) {
        final uri = _uri(path);
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

      final uri = _uri(path);
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
        throw SeedsInventoryUnauthorizedException(message: e.message);
      }
      if (e.isNetworkError) {
        throw SeedsInventoryNetworkException(message: e.message);
      }
      throw SeedsInventoryException(
        message: e.message,
        statusCode: e.statusCode,
      );
    } on SocketException catch (_) {
      throw const SeedsInventoryNetworkException();
    } on http.ClientException catch (_) {
      throw const SeedsInventoryNetworkException();
    } on TimeoutException catch (_) {
      throw SeedsInventoryNetworkException(message: timeoutMessage);
    }
  }

  @override
  Future<List<SeedInventoryItem>> getSeeds({required String accessToken}) async {
    final response = await _send(
      'GET',
      '/seeds',
      accessToken: accessToken,
      timeoutMessage: 'Request timed out while loading seed inventory.',
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
        .map((m) => SeedInventoryItem.fromJson(m))
        .toList();
  }

  @override
  Future<SeedInventoryItem> getSeed({
    required String accessToken,
    required String seedId,
  }) async {
    final response = await _send(
      'GET',
      '/seeds/$seedId',
      accessToken: accessToken,
      timeoutMessage: 'Request timed out while loading seed details.',
    );

    final json = _parseResponse(response);
    final data = (json is Map<String, dynamic> && json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json is Map<String, dynamic> ? json : <String, dynamic>{});

    return SeedInventoryItem.fromJson(data);
  }

  @override
  Future<SeedInventoryItem> createSeed({
    required String accessToken,
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
    final payload = <String, dynamic>{
      'name': name.trim(),
      'price_per_kg': pricePerKg,
      'stock_kg': stockKg,
    };
    if (cropType != null && cropType.trim().isNotEmpty) {
      payload['crop_type'] = cropType.trim();
    }
    if (variety != null && variety.trim().isNotEmpty) {
      payload['variety'] = variety.trim();
    }
    if (priceGradeA != null) {
      payload['price_grade_a'] = priceGradeA;
    }
    if (priceGradeB != null) {
      payload['price_grade_b'] = priceGradeB;
    }
    if (priceGradeC != null) {
      payload['price_grade_c'] = priceGradeC;
    }
    if (maxOrderQuantityKg != null) {
      payload['max_order_quantity_kg'] = maxOrderQuantityKg;
    }
    if (warehouseIds != null && warehouseIds.isNotEmpty) {
      payload['warehouse_ids'] = warehouseIds;
    }
    if (description != null && description.trim().isNotEmpty) {
      payload['description'] = description.trim();
    }
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      payload['image_url'] = imageUrl.trim();
    }

    final response = await _send(
      'POST',
      '/seeds',
      accessToken: accessToken,
      body: jsonEncode(payload),
      timeoutMessage: 'Request timed out while creating seed product.',
    );

    final json = _parseResponse(response);
    final data = (json is Map<String, dynamic> && json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json is Map<String, dynamic> ? json : <String, dynamic>{});

    return SeedInventoryItem.fromJson(data);
  }

  @override
  Future<SeedInventoryItem> updateSeed({
    required String accessToken,
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
    final payload = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) payload['name'] = name.trim();
    if (cropType != null) payload['crop_type'] = cropType.trim().isEmpty ? null : cropType.trim();
    if (variety != null) payload['variety'] = variety.trim().isEmpty ? null : variety.trim();
    if (pricePerKg != null) payload['price_per_kg'] = pricePerKg;
    if (priceGradeA != null) payload['price_grade_a'] = priceGradeA;
    if (priceGradeB != null) payload['price_grade_b'] = priceGradeB;
    if (priceGradeC != null) payload['price_grade_c'] = priceGradeC;
    if (maxOrderQuantityKg != null) payload['max_order_quantity_kg'] = maxOrderQuantityKg;
    if (stockKg != null) payload['stock_kg'] = stockKg;
    if (warehouseIds != null) payload['warehouse_ids'] = warehouseIds;
    if (description != null) payload['description'] = description.trim();
    if (imageUrl != null) payload['image_url'] = imageUrl.trim();
    if (isActive != null) payload['is_active'] = isActive;

    final response = await _send(
      'PATCH',
      '/seeds/$seedId',
      accessToken: accessToken,
      body: jsonEncode(payload),
      timeoutMessage: 'Request timed out while updating seed product.',
    );

    final json = _parseResponse(response);
    final data = (json is Map<String, dynamic> && json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json is Map<String, dynamic> ? json : <String, dynamic>{});

    return SeedInventoryItem.fromJson(data);
  }

  @override
  Future<void> deleteSeed({
    required String accessToken,
    required String seedId,
  }) async {
    final response = await _send(
      'DELETE',
      '/seeds/$seedId',
      accessToken: accessToken,
      timeoutMessage: 'Request timed out while deleting seed product.',
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      return;
    }
    _parseResponse(response);
  }

  @override
  Future<List<SeedWarehouseBrief>> getWarehouses({required String accessToken}) async {
    final response = await _send(
      'GET',
      '/warehouses',
      accessToken: accessToken,
      timeoutMessage: 'Request timed out while loading warehouses.',
    );

    final json = _parseResponse(response);
    List<dynamic> list = [];
    if (json is Map<String, dynamic> && json['data'] is List) {
      list = json['data'] as List<dynamic>;
    } else if (json is List) {
      list = json;
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => SeedWarehouseBrief.fromJson(m))
        .toList();
  }

  @override
  Future<List<SeedWarehouseBrief>> getSeedWarehouses({
    required String accessToken,
    required String seedId,
  }) async {
    final response = await _send(
      'GET',
      '/seeds/$seedId/warehouses',
      accessToken: accessToken,
      timeoutMessage: 'Request timed out while loading seed warehouses.',
    );

    final json = _parseResponse(response);
    List<dynamic> list = [];
    if (json is Map<String, dynamic> && json['data'] is List) {
      list = json['data'] as List<dynamic>;
    } else if (json is List) {
      list = json;
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => SeedWarehouseBrief.fromJson(m))
        .toList();
  }

  @override
  Future<List<SeedWarehouseBrief>> assignSeedWarehouses({
    required String accessToken,
    required String seedId,
    required List<String> warehouseIds,
  }) async {
    final response = await _send(
      'POST',
      '/seeds/$seedId/warehouses',
      accessToken: accessToken,
      body: jsonEncode({'warehouse_ids': warehouseIds}),
      timeoutMessage: 'Request timed out while assigning seed warehouses.',
    );

    final json = _parseResponse(response);
    List<dynamic> list = [];
    if (json is Map<String, dynamic> && json['data'] is List) {
      list = json['data'] as List<dynamic>;
    } else if (json is List) {
      list = json;
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => SeedWarehouseBrief.fromJson(m))
        .toList();
  }

  @override
  Future<void> removeSeedWarehouse({
    required String accessToken,
    required String seedId,
    required String warehouseId,
  }) async {
    final response = await _send(
      'DELETE',
      '/seeds/$seedId/warehouses/$warehouseId',
      accessToken: accessToken,
      timeoutMessage: 'Request timed out while removing seed warehouse.',
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      return;
    }
    _parseResponse(response);
  }

  @override
  Future<String> uploadSeedImage({
    required String accessToken,
    required List<int> fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final token =
          (await apiClient?.localDataSource.getAccessToken()) ?? accessToken;
      final request = http.MultipartRequest('POST', _uri('/uploads'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['bucket'] = 'seeds';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ));

      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final json = _parseResponse(response);

      final publicUrl = _extractPublicUrl(json);
      if (publicUrl != null) return publicUrl;
      throw const SeedsInventoryException(
        message: 'Image upload completed, but the server did not return a public image URL.',
      );
    } on SeedsInventoryException catch (e) {
      throw SeedsInventoryException(
        message: _uploadErrorMessage(e),
        statusCode: e.statusCode,
        isNetworkError: e.isNetworkError,
      );
    } on SocketException catch (_) {
      throw const SeedsInventoryNetworkException(
        message: 'Unable to upload image. Check your connection.',
      );
    } on http.ClientException catch (_) {
      throw const SeedsInventoryNetworkException(
        message: 'Unable to upload image. Check your connection.',
      );
    } on TimeoutException catch (_) {
      throw const SeedsInventoryNetworkException(
        message: 'Unable to upload image. Check your connection.',
      );
    }
  }

  /// Reads the verified contract fields `data.public_url` or `public_url`.
  /// Returns `null` when neither is present or usable; never constructs a URL.
  static String? _extractPublicUrl(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    String? value;
    if (json['data'] is Map<String, dynamic>) {
      final nested = json['data']['public_url']?.toString().trim();
      if (nested != null && nested.isNotEmpty) value = nested;
    }
    value ??= json['public_url']?.toString().trim();
    return (value != null && value.isNotEmpty) ? value : null;
  }

  /// Maps any upload-path exception to a fixed, sanitized user message.
  /// Never surfaces backend detail text, transport internals, or tokens.
  static String _uploadErrorMessage(SeedsInventoryException e) {
    if (e.isNetworkError) return 'Unable to upload image. Check your connection.';
    final status = e.statusCode;
    // Null status means the exception was raised on the upload path itself
    // with a fixed message (missing public URL) — already sanitized.
    if (status == null) return e.message;
    if (status == 401) return 'Image upload is not authorized.';
    if (status == 422) return 'Image upload was rejected by the server.';
    if (status >= 500) return 'Image upload service is temporarily unavailable.';
    // Statuses with fixed constants in the central sanitizer (403/404/409).
    if (status == 403 || status == 404 || status == 409) return ErrorSanitizer.sanitize(e);
    // Any other status: generic message, never backend detail.
    return ErrorSanitizer.genericErrorMessage;
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

    String message = 'Seeds inventory operation failed (${response.statusCode})';
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
        throw SeedsInventoryUnauthorizedException(message: message);
      case 403:
        throw SeedsInventoryForbiddenException(message: message);
      case 404:
        throw SeedsInventoryNotFoundException(message: message);
      case 422:
        throw SeedsInventoryValidationException(message: message);
      default:
        if (statusCode >= 500) {
          throw SeedsInventoryServerException(message: message);
        }
        throw SeedsInventoryException(
          message: message,
          statusCode: statusCode,
        );
    }
  }
}
