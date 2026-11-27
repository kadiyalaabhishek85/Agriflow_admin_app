import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:agriflow_admin/core/network/api_client.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import 'package:agriflow_admin/features/farmers/data/farmer_lookup_service.dart';
import '../../domain/entities/grain_sale_exception.dart';
import '../../domain/entities/grain_sale_item.dart';
import '../../domain/entities/grain_sale_pagination.dart';

/// Abstract remote data source contract for Grain Sales.
abstract class GrainSaleRemoteDataSource {
  Future<({List<GrainSaleItem> items, GrainSalePagination pagination})> getGrainSales({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? sort,
    String? order,
  });

  Future<GrainSaleItem> procureCrop({
    required String accessToken,
    required String farmerId,
    required String grainType,
    required String grade,
    required double rawMaterialKg,
    required double goodMaterialKg,
    required double wastageKg,
  });

  Future<GrainSaleItem> reviewGrainSale({
    required String accessToken,
    required String saleId,
    String? bookingSlotId,
    required double goodQuantityKg,
    required double badQuantityKg,
    bool approve = true,
    String? rejectionReason,
  });

  Future<GrainSaleItem> payGrainSale({
    required String accessToken,
    required String saleId,
    String? paymentReference,
  });

  Future<GrainSaleItem> updateGrainYield({
    required String accessToken,
    required String saleId,
    required double goodMaterialKg,
    required double wastageKg,
  });

  Future<Map<String, ({String name, String phone, String? village})>> getFarmers({
    required String accessToken,
  });
}

/// FastAPI implementation of GrainSaleRemoteDataSource.
class FastApiGrainSaleRemoteDataSource implements GrainSaleRemoteDataSource {
  static const String defaultBaseUrl = ApiClient.defaultBaseUrl;
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;
  final ApiClient? apiClient;

  FastApiGrainSaleRemoteDataSource({
    String? baseUrl,
    http.Client? client,
    this.apiClient,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

  Future<http.Response> _send(
    String method,
    String path, {
    required String accessToken,
    Map<String, dynamic>? queryParameters,
    Object? body,
  }) async {
    final uri = _uri(path, queryParameters);
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
        }
      }

      final headers = _headers(token: accessToken);
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
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
    } on AuthException catch (e) {
      if (e.statusCode == 401 || e.errorCode == 'SESSION_EXPIRED') {
        throw GrainSaleUnauthorizedException(message: e.message);
      }
      if (e.isNetworkError) {
        throw GrainSaleException(message: e.message, isNetworkError: true);
      }
      throw GrainSaleException(message: e.message, statusCode: e.statusCode);
    } on SocketException catch (_) {
      throw const GrainSaleException(
        message: 'Network connection unavailable. Please check your internet connection.',
        isNetworkError: true,
      );
    } on http.ClientException catch (_) {
      throw const GrainSaleException(
        message: 'Network connection unavailable. Please check your internet connection.',
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const GrainSaleException(
        message: 'Server request timed out. Please try again later.',
        isNetworkError: true,
      );
    }
  }

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = Uri.parse('$baseUrl$apiPrefix$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final cleanParams = <String, String>{};
      queryParameters.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          cleanParams[key] = value.toString();
        }
      });
      return base.replace(queryParameters: cleanParams);
    }
    return base;
  }

  Map<String, String> _headers({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Never _handleErrorResponse(http.Response response) {
    String message = 'Request failed with status ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['detail'] != null) {
          message = body['detail'].toString();
        } else if (body['message'] != null) {
          message = body['message'].toString();
        } else if (body['error'] != null) {
          final err = body['error'];
          if (err is Map && err['message'] != null) {
            message = err['message'].toString();
          } else {
            message = err.toString();
          }
        }
      }
    } catch (_) {
      // Body not JSON, keep default status message
    }

    switch (response.statusCode) {
      case 401:
        throw GrainSaleUnauthorizedException(message: message);
      case 403:
        throw GrainSaleForbiddenException(message: message);
      case 404:
        throw GrainSaleNotFoundException(message: message);
      case 409:
        throw GrainSaleConflictException(message: message);
      case 422:
        throw GrainSaleValidationException(message: message);
      default:
        throw GrainSaleServerException(message: message);
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
    try {
      final query = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (search != null && search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }
      if (status != null && status.trim().isNotEmpty && status.toLowerCase() != 'all') {
        query['status'] = status.trim().toLowerCase();
      }
      if (sort != null && sort.isNotEmpty) {
        query['sort'] = sort;
      }
      if (order != null && order.isNotEmpty) {
        query['order'] = order;
      }

      final response = await _send(
        'GET',
        '/grain-sales',
        accessToken: accessToken,
        queryParameters: query,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>? ?? [];
        final items = data
            .whereType<Map<String, dynamic>>()
            .map((item) => GrainSaleItem.fromJson(item))
            .toList();

        final paginationJson = json['pagination'] as Map<String, dynamic>? ?? {};
        final pagination = GrainSalePagination.fromJson(paginationJson);

        return (items: items, pagination: pagination);
      }

      _handleErrorResponse(response);
    } catch (e) {
      if (e is GrainSaleException) rethrow;
      rethrow;
    }
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
    final payload = {
      'farmer_id': farmerId,
      'grain_type': grainType,
      'grade': grade,
      'raw_material_kg': rawMaterialKg,
      'good_material_kg': goodMaterialKg,
      'wastage_kg': wastageKg,
    };

    final response = await _send(
      'POST',
      '/grain-sales/procure',
      accessToken: accessToken,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? json;
      return GrainSaleItem.fromJson(data);
    }

    _handleErrorResponse(response);
  }

  @override
  Future<GrainSaleItem> reviewGrainSale({
    required String accessToken,
    required String saleId,
    String? bookingSlotId,
    required double goodQuantityKg,
    required double badQuantityKg,
    bool approve = true,
    String? rejectionReason,
  }) async {
    final payload = <String, dynamic>{
      if (bookingSlotId != null && bookingSlotId.isNotEmpty)
        'booking_slot_id': bookingSlotId,
      'good_quantity_kg': goodQuantityKg,
      'bad_quantity_kg': badQuantityKg,
      'approve': approve,
      if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
        'rejection_reason': rejectionReason.trim(),
    };

    final response = await _send(
      'PATCH',
      '/grain-sales/$saleId/review',
      accessToken: accessToken,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? json;
      return GrainSaleItem.fromJson(data);
    }

    _handleErrorResponse(response);
  }

  @override
  Future<GrainSaleItem> payGrainSale({
    required String accessToken,
    required String saleId,
    String? paymentReference,
  }) async {
    final payload = <String, dynamic>{};
    if (paymentReference != null && paymentReference.trim().isNotEmpty) {
      payload['payment_reference'] = paymentReference.trim();
    }

    final response = await _send(
      'PATCH',
      '/grain-sales/$saleId/pay',
      accessToken: accessToken,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? json;
      return GrainSaleItem.fromJson(data);
    }

    _handleErrorResponse(response);
  }

  @override
  Future<GrainSaleItem> updateGrainYield({
    required String accessToken,
    required String saleId,
    required double goodMaterialKg,
    required double wastageKg,
  }) async {
    final payload = <String, dynamic>{
      'good_material_kg': goodMaterialKg,
      'wastage_kg': wastageKg,
    };

    final response = await _send(
      'PATCH',
      '/grain-sales/$saleId/yield',
      accessToken: accessToken,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? json;
      return GrainSaleItem.fromJson(data);
    }

    _handleErrorResponse(response);
  }

  @override
  Future<Map<String, ({String name, String phone, String? village})>> getFarmers({
    required String accessToken,
  }) async {
    try {
      final token =
          (await apiClient?.localDataSource.getAccessToken()) ?? accessToken;
      return await FarmerLookupService.fetch(
        accessToken: token,
        baseUrl: baseUrl,
        apiPrefix: apiPrefix,
        client: client,
      );
    } catch (_) {
      return {};
    }
  }
}

typedef GrainSaleRemoteDataSourceImpl = FastApiGrainSaleRemoteDataSource;
