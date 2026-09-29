import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:agriflow_admin/features/farmers/data/farmer_lookup_service.dart';
import '../../domain/entities/farm_visit_exception.dart';
import '../../domain/entities/farm_visit_item.dart';
import '../../domain/entities/farm_visit_pagination.dart';

abstract class FarmVisitRemoteDataSource {
  Future<({List<FarmVisitItem> items, FarmVisitPagination pagination})> getVisits({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  });

  Future<FarmVisitItem> scheduleVisit({
    required String accessToken,
    required String visitId,
    String? scheduledDate,
    String? staffId,
  });

  Future<FarmVisitItem> completeVisit({
    required String accessToken,
    required String visitId,
    required String verifiedAcres,
    required String report,
    String? diagnosis,
    String? recommendation,
  });

  Future<FarmVisitItem> createVisit({
    required String accessToken,
    required String cropId,
    required int visitMonth,
    required String scheduledDate,
    String? staffId,
  });

  /// POST /farm-visits/reminders?days_ahead=N — returns the backend message.
  Future<String> sendReminders({
    required String accessToken,
    int daysAhead = 2,
  });

  Future<String> uploadVisitPhoto({
    required String accessToken,
    required List<int> fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  });

  Future<Map<String, ({String name, String phone, String? village})>> getFarmerLookup({
    required String accessToken,
  });

  Future<Map<String, ({String cropType, String acres})>> getCropLookup({
    required String accessToken,
  });

  Future<Map<String, ({String name, String phone})>> getStaffLookup({
    required String accessToken,
  });
}

class FarmVisitRemoteDataSourceImpl implements FarmVisitRemoteDataSource {
  static const String defaultBaseUrl = 'https://agriflow-backend-t8o4.onrender.com';
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;

  FarmVisitRemoteDataSourceImpl({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

  Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    final base = Uri.parse('$baseUrl$apiPrefix$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return base.replace(queryParameters: queryParams);
    }
    return base;
  }

  Map<String, String> _buildHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Never _handleErrorResponse(http.Response response) {
    String message = 'Request failed with status ${response.statusCode}';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['detail'] != null) {
          message = decoded['detail'].toString();
        } else if (decoded['error'] is Map && decoded['error']['message'] != null) {
          message = decoded['error']['message'].toString();
        } else if (decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 401:
        throw const FarmVisitAuthException();
      case 403:
        throw const FarmVisitPermissionException();
      case 404:
        throw const FarmVisitNotFoundException();
      case 409:
        throw const FarmVisitConflictException();
      case 422:
        throw FarmVisitValidationException(message);
      default:
        if (response.statusCode >= 500) {
          throw FarmVisitServerException('Server error (${response.statusCode}). Please try again shortly.', response.statusCode);
        }
        throw FarmVisitValidationException(message, response.statusCode);
    }
  }

  @override
  Future<({List<FarmVisitItem> items, FarmVisitPagination pagination})> getVisits({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'sort': 'created_at',
        'order': 'desc',
      };

      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      if (status != null && status.trim().isNotEmpty && status.toLowerCase() != 'all') {
        queryParams['status'] = status.trim().toLowerCase();
      }

      final uri = _uri('/farm-visits', queryParams);
      final response = await client.get(uri, headers: _buildHeaders(accessToken)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          final itemsList = <FarmVisitItem>[];

          if (data is List) {
            for (final raw in data) {
              if (raw is Map<String, dynamic>) {
                itemsList.add(FarmVisitItem.fromJson(raw));
              }
            }
          }

          final pagination = decoded['pagination'] is Map<String, dynamic>
              ? FarmVisitPagination.fromJson(decoded['pagination'] as Map<String, dynamic>)
              : FarmVisitPagination(
                  page: page,
                  pageSize: pageSize,
                  total: itemsList.length,
                  totalPages: 1,
                );

          return (items: itemsList, pagination: pagination);
        }
      }

      _handleErrorResponse(response);
    } on SocketException {
      throw const FarmVisitNetworkException();
    } on http.ClientException catch (e) {
      throw FarmVisitNetworkException('Network error: ${e.message}');
    } on TimeoutException catch (_) {
      throw const FarmVisitNetworkException(
        'Server request timed out. Please try again later.',
      );
    } catch (e) {
      if (e is FarmVisitException) rethrow;
      throw FarmVisitServerException('Failed to fetch farm visits: ${e.toString()}');
    }
  }

  @override
  Future<FarmVisitItem> scheduleVisit({
    required String accessToken,
    required String visitId,
    String? scheduledDate,
    String? staffId,
  }) async {
    try {
      final uri = _uri('/farm-visits/$visitId/schedule');
      final body = <String, dynamic>{};
      if (scheduledDate != null) body['scheduled_date'] = scheduledDate;
      if (staffId != null) body['staff_id'] = staffId;

      final response = await client.patch(
        uri,
        headers: _buildHeaders(accessToken),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'] ?? decoded;
          if (data is Map<String, dynamic>) {
            return FarmVisitItem.fromJson(data);
          }
        }
      }

      _handleErrorResponse(response);
    } on SocketException {
      throw const FarmVisitNetworkException();
    } on http.ClientException catch (e) {
      throw FarmVisitNetworkException('Network error: ${e.message}');
    } on TimeoutException catch (_) {
      throw const FarmVisitNetworkException(
        'Server request timed out. Please try again later.',
      );
    } catch (e) {
      if (e is FarmVisitException) rethrow;
      throw FarmVisitServerException('Failed to schedule visit: ${e.toString()}');
    }
  }

  @override
  Future<FarmVisitItem> completeVisit({
    required String accessToken,
    required String visitId,
    required String verifiedAcres,
    required String report,
    String? diagnosis,
    String? recommendation,
  }) async {
    try {
      final uri = _uri('/farm-visits/$visitId/complete');
      final body = <String, dynamic>{
        'verified_acres': verifiedAcres,
        'report': report,
      };
      if (diagnosis != null && diagnosis.trim().isNotEmpty) {
        body['diagnosis'] = diagnosis.trim();
      }
      if (recommendation != null && recommendation.trim().isNotEmpty) {
        body['recommendation'] = recommendation.trim();
      }

      final response = await client.patch(
        uri,
        headers: _buildHeaders(accessToken),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'] ?? decoded;
          if (data is Map<String, dynamic>) {
            return FarmVisitItem.fromJson(data);
          }
        }
      }

      _handleErrorResponse(response);
    } on SocketException {
      throw const FarmVisitNetworkException();
    } on http.ClientException catch (e) {
      throw FarmVisitNetworkException('Network error: ${e.message}');
    } on TimeoutException catch (_) {
      throw const FarmVisitNetworkException(
        'Server request timed out. Please try again later.',
      );
    } catch (e) {
      if (e is FarmVisitException) rethrow;
      throw FarmVisitServerException('Failed to complete visit: ${e.toString()}');
    }
  }

  @override
  Future<FarmVisitItem> createVisit({
    required String accessToken,
    required String cropId,
    required int visitMonth,
    required String scheduledDate,
    String? staffId,
  }) async {
    try {
      final uri = _uri('/farm-visits');
      final body = <String, dynamic>{
        'crop_id': cropId,
        'visit_month': visitMonth,
        'scheduled_date': scheduledDate,
      };
      if (staffId != null && staffId.isNotEmpty) {
        body['staff_id'] = staffId;
      }

      final response = await client.post(
        uri,
        headers: _buildHeaders(accessToken),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'] ?? decoded;
          if (data is Map<String, dynamic>) {
            return FarmVisitItem.fromJson(data);
          }
        }
      }

      _handleErrorResponse(response);
    } on SocketException {
      throw const FarmVisitNetworkException();
    } on http.ClientException catch (e) {
      throw FarmVisitNetworkException('Network error: ${e.message}');
    } on TimeoutException catch (_) {
      throw const FarmVisitNetworkException(
        'Server request timed out. Please try again later.',
      );
    } catch (e) {
      if (e is FarmVisitException) rethrow;
      throw FarmVisitServerException('Failed to create visit: ${e.toString()}');
    }
  }

  @override
  Future<String> sendReminders({
    required String accessToken,
    int daysAhead = 2,
  }) async {
    try {
      final uri = _uri('/farm-visits/reminders', {'days_ahead': '$daysAhead'});
      final response = await client.post(
        uri,
        headers: _buildHeaders(accessToken),
        body: jsonEncode(const <String, dynamic>{}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final data = decoded['data'];
            if (data is Map<String, dynamic> && data['message'] != null) {
              return data['message'].toString();
            }
            if (decoded['message'] != null) {
              return decoded['message'].toString();
            }
          }
        } catch (_) {}
        return 'Visit reminders sent.';
      }

      _handleErrorResponse(response);
    } on SocketException {
      throw const FarmVisitNetworkException();
    } on http.ClientException catch (e) {
      throw FarmVisitNetworkException('Network error: ${e.message}');
    } on TimeoutException catch (_) {
      throw const FarmVisitNetworkException(
        'Server request timed out. Please try again later.',
      );
    } catch (e) {
      if (e is FarmVisitException) rethrow;
      throw FarmVisitServerException('Failed to send reminders: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, ({String name, String phone, String? village})>> getFarmerLookup({
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

  @override
  Future<Map<String, ({String cropType, String acres})>> getCropLookup({
    required String accessToken,
  }) async {
    try {
      final uri = _uri('/crops', {'page': '1', 'page_size': '100'});
      final response = await client.get(uri, headers: _buildHeaders(accessToken)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final lookup = <String, ({String cropType, String acres})>{};
        final data = decoded is Map<String, dynamic> ? decoded['data'] : decoded;

        if (data is List) {
          for (final raw in data) {
            if (raw is Map<String, dynamic>) {
              final id = raw['id']?.toString() ?? '';
              final cropType = raw['crop_type']?.toString() ?? 'Crop';
              final acres = raw['acres']?.toString() ?? '';
              if (id.isNotEmpty) {
                lookup[id] = (cropType: cropType, acres: acres);
              }
            }
          }
        }
        return lookup;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<Map<String, ({String name, String phone})>> getStaffLookup({
    required String accessToken,
  }) async {
    try {
      final uri = _uri('/managers', {'page': '1', 'page_size': '100'});
      final response = await client.get(uri, headers: _buildHeaders(accessToken)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final lookup = <String, ({String name, String phone})>{};
        final data = decoded is Map<String, dynamic> ? decoded['data'] : decoded;

        if (data is List) {
          for (final raw in data) {
            if (raw is Map<String, dynamic>) {
              final id = raw['id']?.toString() ?? '';
              final name = raw['name']?.toString() ?? '';
              final phone = raw['phone']?.toString() ?? '';
              if (id.isNotEmpty) {
                lookup[id] = (name: name, phone: phone);
              }
            }
          }
        }
        return lookup;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<String> uploadVisitPhoto({
    required String accessToken,
    required List<int> fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final request = http.MultipartRequest('POST', _uri('/uploads'));
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields['bucket'] = 'visits';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ));

      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final publicUrl = _extractPublicUrl(decoded);
        if (publicUrl != null && publicUrl.isNotEmpty) {
          return publicUrl;
        }
        throw const FarmVisitValidationException(
          'Photo upload completed, but the server did not return a public image URL.',
        );
      }

      _handleErrorResponse(response);
    } on FarmVisitException {
      rethrow;
    } on SocketException catch (_) {
      throw const FarmVisitNetworkException('Unable to upload field photo. Check your connection.');
    } on TimeoutException catch (_) {
      throw const FarmVisitNetworkException('Field photo upload timed out.');
    } catch (e) {
      throw FarmVisitValidationException('Unable to upload photo: ${e.toString()}');
    }
  }

  static String? _extractPublicUrl(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    String? value;
    if (json['data'] is Map<String, dynamic>) {
      final nested = json['data']['public_url']?.toString().trim();
      if (nested != null && nested.isNotEmpty) value = nested;
    }
    if (value == null) {
      final top = json['public_url']?.toString().trim();
      if (top != null && top.isNotEmpty) value = top;
    }
    return value;
  }
}
