import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
    required String bookingSlotId,
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
  static const String defaultBaseUrl = 'https://agriflow-backend-t8o4.onrender.com';
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;

  FastApiGrainSaleRemoteDataSource({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

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

      final uri = _uri('/grain-sales', query);
      final response = await client
          .get(uri, headers: _headers(token: accessToken))
          .timeout(const Duration(seconds: 15));

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
    } on SocketException catch (_) {
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
    try {
      final uri = _uri('/grain-sales/procure');
      final payload = {
        'farmer_id': farmerId,
        'grain_type': grainType,
        'grade': grade,
        'raw_material_kg': rawMaterialKg,
        'good_material_kg': goodMaterialKg,
        'wastage_kg': wastageKg,
      };

      final response = await client
          .post(
            uri,
            headers: _headers(token: accessToken),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>? ?? json;
        return GrainSaleItem.fromJson(data);
      }

      _handleErrorResponse(response);
    } on SocketException catch (_) {
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

  @override
  Future<GrainSaleItem> reviewGrainSale({
    required String accessToken,
    required String saleId,
    required String bookingSlotId,
    required double goodQuantityKg,
    required double badQuantityKg,
    bool approve = true,
    String? rejectionReason,
  }) async {
    try {
      final uri = _uri('/grain-sales/$saleId/review');
      final payload = <String, dynamic>{
        'booking_slot_id': bookingSlotId,
        'good_quantity_kg': goodQuantityKg,
        'bad_quantity_kg': badQuantityKg,
        'approve': approve,
        if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
          'rejection_reason': rejectionReason.trim(),
      };

      final response = await client
          .patch(
            uri,
            headers: _headers(token: accessToken),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>? ?? json;
        return GrainSaleItem.fromJson(data);
      }

      _handleErrorResponse(response);
    } on SocketException catch (_) {
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

  @override
  Future<GrainSaleItem> payGrainSale({
    required String accessToken,
    required String saleId,
    String? paymentReference,
  }) async {
    try {
      final uri = _uri('/grain-sales/$saleId/pay');
      final payload = <String, dynamic>{};
      if (paymentReference != null && paymentReference.trim().isNotEmpty) {
        payload['payment_reference'] = paymentReference.trim();
      }

      final response = await client
          .patch(
            uri,
            headers: _headers(token: accessToken),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>? ?? json;
        return GrainSaleItem.fromJson(data);
      }

      _handleErrorResponse(response);
    } on SocketException catch (_) {
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

  @override
  Future<GrainSaleItem> updateGrainYield({
    required String accessToken,
    required String saleId,
    required double goodMaterialKg,
    required double wastageKg,
  }) async {
    try {
      final uri = _uri('/grain-sales/$saleId/yield');
      final payload = <String, dynamic>{
        'good_material_kg': goodMaterialKg,
        'wastage_kg': wastageKg,
      };

      final response = await client
          .patch(
            uri,
            headers: _headers(token: accessToken),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>? ?? json;
        return GrainSaleItem.fromJson(data);
      }

      _handleErrorResponse(response);
    } on SocketException catch (_) {
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

  @override
  Future<Map<String, ({String name, String phone, String? village})>> getFarmers({
    required String accessToken,
  }) async {
    try {
      return await FarmerLookupService.fetch(
        accessToken: accessToken,
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
