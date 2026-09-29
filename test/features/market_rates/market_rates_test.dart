import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agriflow_admin/core/models/user_role.dart';
import 'package:agriflow_admin/core/network/error_sanitizer.dart';
import 'package:agriflow_admin/core/widgets/custom_drawer.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/admin/presentation/admin_shell.dart';
import 'package:agriflow_admin/features/manager/presentation/manager_shell.dart';

import 'package:agriflow_admin/features/market_rates/data/datasources/market_rates_remote_data_source.dart';
import 'package:agriflow_admin/features/market_rates/data/datasources/fast_api_market_rates_remote_data_source.dart';
import 'package:agriflow_admin/features/market_rates/data/repositories/market_rates_repository_impl.dart';
import 'package:agriflow_admin/features/market_rates/domain/entities/market_rate_group.dart';
import 'package:agriflow_admin/features/market_rates/domain/entities/market_rate_item.dart';
import 'package:agriflow_admin/features/market_rates/domain/exceptions/market_rates_exception.dart';
import 'package:agriflow_admin/features/market_rates/domain/repositories/market_rates_repository.dart';
import 'package:agriflow_admin/features/market_rates/presentation/controllers/market_rates_controller.dart';
import 'package:agriflow_admin/features/market_rates/presentation/screens/market_rates_screen.dart';
import 'package:agriflow_admin/features/market_rates/presentation/widgets/market_rate_card.dart';
import 'package:agriflow_admin/features/market_rates/presentation/widgets/set_rate_sheet.dart';

// -------------------------------------------------------------
// Mock Data Source for Unit & Widget Tests
// -------------------------------------------------------------

class _MockMarketRatesRemoteDataSource implements MarketRatesRemoteDataSource {
  List<MarketRateItem> ratesToReturn = [];
  Exception? getErrorToThrow;
  Exception? setErrorToThrow;

  /// When set together with [setErrorToThrow], only this grade fails —
  /// used to prove partial-failure reporting.
  String? failOnGrade;

  int getRatesCallCount = 0;
  int getPublicRatesCallCount = 0;
  int setRateCallCount = 0;
  final List<Map<String, dynamic>> setRatePayloads = [];

  @override
  Future<List<MarketRateItem>> getRates({required String accessToken}) async {
    getRatesCallCount++;
    if (getErrorToThrow != null) throw getErrorToThrow!;
    return ratesToReturn;
  }

  @override
  Future<List<MarketRateItem>> getPublicRates() async {
    getPublicRatesCallCount++;
    if (getErrorToThrow != null) throw getErrorToThrow!;
    return ratesToReturn;
  }

  @override
  Future<void> setRate({
    required String accessToken,
    required String cropType,
    required String grade,
    required double pricePerKg,
    required String effectiveDate,
  }) async {
    setRateCallCount++;
    setRatePayloads.add({
      'accessToken': accessToken,
      'crop_type': cropType,
      'grade': grade,
      'price_per_kg': pricePerKg,
      'effective_date': effectiveDate,
    });
    if (setErrorToThrow != null &&
        (failOnGrade == null || failOnGrade == grade)) {
      throw setErrorToThrow!;
    }
  }
}

// -------------------------------------------------------------
// Sample Test Data
// -------------------------------------------------------------

final sampleRiceA = MarketRateItem(
  id: 'mr-1',
  cropType: 'Rice',
  grade: 'A',
  pricePerKg: 21.5,
  effectiveDate: '2026-09-28',
);

final sampleRiceB = MarketRateItem(
  id: 'mr-2',
  cropType: 'Rice',
  grade: 'B',
  pricePerKg: 20.25,
  effectiveDate: '2026-09-28',
);

final sampleWheatA = MarketRateItem(
  id: 'mr-3',
  cropType: 'Wheat',
  grade: 'A',
  pricePerKg: 24.0,
  effectiveDate: '2026-09-27',
);

final sampleMaizeC = MarketRateItem(
  id: 'mr-4',
  cropType: 'Maize',
  grade: 'C',
  pricePerKg: 18.75,
  effectiveDate: '2026-09-26',
);

final List<MarketRateItem> sampleRates = [
  sampleRiceA,
  sampleRiceB,
  sampleWheatA,
  sampleMaizeC,
];

Map<String, dynamic> rateJson({
  String id = 'mr-1',
  String cropType = 'Rice',
  dynamic grade = 'A',
  dynamic pricePerKg = 21.5,
  dynamic effectiveDate = '2026-09-28',
}) {
  return {
    'id': id,
    'crop_type': cropType,
    'grade': grade,
    'price_per_kg': pricePerKg,
    'effective_date': effectiveDate,
  };
}

MarketRatesController _buildController({
  _MockMarketRatesRemoteDataSource? mockDs,
  UserRole role = UserRole.admin,
}) {
  final ds = mockDs ?? _MockMarketRatesRemoteDataSource();
  return MarketRatesController(
    repository: MarketRatesRepositoryImpl(remoteDataSource: ds),
    accessToken: 'test_token',
    role: role,
  );
}

Future<void> openSheetHarness(
  WidgetTester tester,
  MarketRatesController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            key: const ValueKey('open-sheet'),
            onPressed: () => SetRateSheet.show(context, controller: controller),
            child: const Text('Open Sheet'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('open-sheet')));
  await tester.pumpAndSettle();
}

Future<void> selectCrop(WidgetTester tester, String crop) async {
  await tester.ensureVisible(find.byKey(const ValueKey('set-rate-crop-dropdown')));
  await tester.tap(find.byKey(const ValueKey('set-rate-crop-dropdown')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(crop).last);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone 5 Step 9 — Domain Entity Unit Tests', () {
    test('MarketRateItem parses complete MarketRatePublic payload cleanly', () {
      final item = MarketRateItem.fromJson(rateJson());

      expect(item.id, 'mr-1');
      expect(item.cropType, 'Rice');
      expect(item.grade, 'A');
      expect(item.pricePerKg, 21.5);
      expect(item.effectiveDate, '2026-09-28');
      expect(item.effectiveDateTime, DateTime(2026, 9, 28));
      expect(item.displayPricePerKg, 21.5);
      expect(item.displayPricePerQtl, 2150.0);
    });

    test('MarketRateItem parses string prices and lowercase grades', () {
      final item = MarketRateItem.fromJson(
        rateJson(grade: 'b', pricePerKg: '20.25', effectiveDate: null),
      );

      expect(item.grade, 'B');
      expect(item.pricePerKg, 20.25);
      expect(item.effectiveDate, isNull);
      expect(item.effectiveDateTime, isNull);
    });

    test('MarketRateItem throws MarketRatesException on invalid price (no fabrication)', () {
      expect(
        () => MarketRateItem.fromJson(rateJson(pricePerKg: 'not-a-price')),
        throwsA(isA<MarketRatesException>()),
      );
      expect(
        () => MarketRateItem.fromJson(rateJson(pricePerKg: null)),
        throwsA(isA<MarketRatesException>()),
      );
    });

    test('MarketRateItem throws MarketRatesException on missing/empty grade (no fabrication)', () {
      expect(
        () => MarketRateItem.fromJson(rateJson(grade: null)),
        throwsA(isA<MarketRatesException>()),
      );
      expect(
        () => MarketRateItem.fromJson(rateJson(grade: '  ')),
        throwsA(isA<MarketRatesException>()),
      );
    });

    test('Quintal conversion and en_IN currency labels are presentation-only', () {
      expect(sampleRiceA.displayPricePerKgLabel, '₹21.50');
      expect(sampleRiceA.displayPricePerQtlLabel, '₹2,150');

      final artifact = MarketRateItem(
        id: 'x',
        cropType: 'Wheat',
        grade: 'A',
        pricePerKg: 22.55,
      );
      expect(artifact.displayPricePerQtlLabel, '₹2,255');
      expect(artifact.pricePerKg, 22.55);
    });

    test('MarketRateItem equality and toString use contract fields', () {
      final clone = MarketRateItem.fromJson(rateJson());
      expect(clone, sampleRiceA);
      expect(clone.hashCode, sampleRiceA.hashCode);
      expect(sampleRiceA.toString(), 'MarketRateItem(Rice Grade A ₹21.5/kg)');
    });

    test('MarketRateItem effectiveDateTime is null for unparsable dates', () {
      final item = MarketRateItem.fromJson(
        rateJson(effectiveDate: 'not-a-date'),
      );
      expect(item.effectiveDate, 'not-a-date');
      expect(item.effectiveDateTime, isNull);
    });

    test('groupRates groups by crop, sorts crops alphabetically and grades A,B,C', () {
      final groups = MarketRateGroup.groupRates([
        sampleWheatA,
        sampleRiceB,
        sampleMaizeC,
        sampleRiceA,
      ]);

      expect(groups.map((g) => g.cropType).toList(), ['Maize', 'Rice', 'Wheat']);
      expect(groups[1].rates.map((r) => r.grade).toList(), ['A', 'B']);
    });

    test('groupRates keeps duplicate grades with latest effective date first', () {
      final older = MarketRateItem(
        id: 'old',
        cropType: 'Rice',
        grade: 'A',
        pricePerKg: 20.0,
        effectiveDate: '2026-01-01',
      );
      final newer = MarketRateItem(
        id: 'new',
        cropType: 'Rice',
        grade: 'A',
        pricePerKg: 22.0,
        effectiveDate: '2026-06-01',
      );

      final groups = MarketRateGroup.groupRates([older, newer]);
      expect(groups.single.rates.first.id, 'new');
      expect(groups.single.rates.last.id, 'old');
    });

    test('groupRates search is case-insensitive; empty query restores all groups', () {
      final all = MarketRateGroup.groupRates(sampleRates);
      expect(all.length, 3);

      final filtered = MarketRateGroup.groupRates(sampleRates, query: '  WHE');
      expect(filtered.map((g) => g.cropType).toList(), ['Wheat']);

      final cleared = MarketRateGroup.groupRates(sampleRates, query: '');
      expect(cleared.length, 3);
    });

    test('MarketRatesException hierarchy maps status codes correctly', () {
      expect(const MarketRatesUnauthorizedException().statusCode, 401);
      expect(const MarketRatesForbiddenException().statusCode, 403);
      expect(const MarketRatesNotFoundException().statusCode, 404);
      expect(
        const MarketRatesValidationException(message: 'Invalid').statusCode,
        422,
      );
      expect(const MarketRatesServerException().statusCode, 500);
      expect(
        const MarketRatesException(message: 'offline', isNetworkError: true)
            .isNetworkError,
        isTrue,
      );
    });
  });

  group('Milestone 5 Step 9 — FastAPI Remote Data Source Tests', () {
    test('getRates performs authenticated GET /market-rates and parses rows', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/market-rates');
        expect(request.headers['Authorization'], 'Bearer test_token');

        return http.Response(
          jsonEncode({
            'data': [
              rateJson(),
              rateJson(
                id: 'mr-3',
                cropType: 'Wheat',
                grade: 'A',
                pricePerKg: 24.0,
              ),
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final ds = FastApiMarketRatesRemoteDataSource(client: mockClient);
      final rows = await ds.getRates(accessToken: 'test_token');

      expect(rows.length, 2);
      expect(rows.first.cropType, 'Rice');
      expect(rows.last.cropType, 'Wheat');
    });

    test('getRates falls back to public endpoint when authenticated GET fails', () async {
      var requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        if (request.url.path == '/api/v1/market-rates') {
          expect(request.headers['Authorization'], 'Bearer expired_token');
          return http.Response(jsonEncode({'detail': 'Token expired'}), 401);
        }
        expect(request.url.path, '/api/v1/public/market-rates');
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response(
          jsonEncode({'data': [rateJson()]}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final ds = FastApiMarketRatesRemoteDataSource(client: mockClient);
      final rows = await ds.getRates(accessToken: 'expired_token');

      expect(rows.length, 1);
      expect(requestCount, 2);
    });

    test('getRates propagates the public endpoint error when both requests fail', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Token expired'}), 401);
      });

      final ds = FastApiMarketRatesRemoteDataSource(client: mockClient);

      await expectLater(
        ds.getRates(accessToken: 'expired_token'),
        throwsA(isA<MarketRatesUnauthorizedException>()),
      );
    });

    test('getPublicRates reads anonymously without an Authorization header', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/public/market-rates');
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response(
          jsonEncode({'data': [rateJson()]}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final ds = FastApiMarketRatesRemoteDataSource(client: mockClient);
      final rows = await ds.getPublicRates();

      expect(rows.single.cropType, 'Rice');
    });

    test('setRate sends MarketRateCreate payload with today-compatible date', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/market-rates');
        expect(request.headers['Authorization'], 'Bearer test_token');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.keys.toSet(), {
          'crop_type',
          'grade',
          'price_per_kg',
          'effective_date',
        });
        expect(body['crop_type'], 'Rice');
        expect(body['grade'], 'A');
        expect(body['price_per_kg'], 22.5);
        expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(body['effective_date'] as String), isTrue);

        return http.Response('{}', 201, headers: {'content-type': 'application/json'});
      });

      final ds = FastApiMarketRatesRemoteDataSource(client: mockClient);
      await ds.setRate(
        accessToken: 'test_token',
        cropType: 'Rice',
        grade: 'A',
        pricePerKg: 22.5,
        effectiveDate: '2026-09-28',
      );
    });

    test('setRate throws MarketRatesUnauthorizedException on 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Token expired'}), 401);
      });

      final ds = FastApiMarketRatesRemoteDataSource(client: mockClient);

      await expectLater(
        ds.setRate(
          accessToken: 'bad_token',
          cropType: 'Rice',
          grade: 'A',
          pricePerKg: 22.5,
          effectiveDate: '2026-09-28',
        ),
        throwsA(isA<MarketRatesUnauthorizedException>()),
      );
    });

    test('setRate throws MarketRatesForbiddenException on 403', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Permission denied'}), 403);
      });

      final ds = FastApiMarketRatesRemoteDataSource(client: mockClient);

      await expectLater(
        ds.setRate(
          accessToken: 'low_priv_token',
          cropType: 'Rice',
          grade: 'A',
          pricePerKg: 22.5,
          effectiveDate: '2026-09-28',
        ),
        throwsA(isA<MarketRatesForbiddenException>()),
      );
    });

    test('setRate throws MarketRatesValidationException with backend detail on 422', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'price_per_kg must be greater than 0'}),
          422,
        );
      });

      final ds = FastApiMarketRatesRemoteDataSource(client: mockClient);

      await expectLater(
        ds.setRate(
          accessToken: 'test_token',
          cropType: 'Rice',
          grade: 'A',
          pricePerKg: 0,
          effectiveDate: '2026-09-28',
        ),
        throwsA(
          isA<MarketRatesValidationException>()
              .having((e) => e.message, 'message', 'price_per_kg must be greater than 0'),
        ),
      );
    });

    test('setRate throws MarketRatesNotFoundException on 404 control path', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Not Found'}), 404);
      });

      final ds = FastApiMarketRatesRemoteDataSource(client: mockClient);

      await expectLater(
        ds.setRate(
          accessToken: 'test_token',
          cropType: 'Rice',
          grade: 'A',
          pricePerKg: 22.5,
          effectiveDate: '2026-09-28',
        ),
        throwsA(isA<MarketRatesNotFoundException>()),
      );
    });

    test('setRate throws MarketRatesServerException on 500', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{}', 500);
      });

      final ds = FastApiMarketRatesRemoteDataSource(client: mockClient);

      await expectLater(
        ds.setRate(
          accessToken: 'test_token',
          cropType: 'Rice',
          grade: 'A',
          pricePerKg: 22.5,
          effectiveDate: '2026-09-28',
        ),
        throwsA(isA<MarketRatesServerException>()),
      );
    });

    test('setRate maps SocketException to a sanitized network MarketRatesException', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('failed host lookup');
      });

      final ds = FastApiMarketRatesRemoteDataSource(client: mockClient);

      await expectLater(
        ds.setRate(
          accessToken: 'test_token',
          cropType: 'Rice',
          grade: 'A',
          pricePerKg: 22.5,
          effectiveDate: '2026-09-28',
        ),
        throwsA(
          isA<MarketRatesException>().having(
            (e) => e.isNetworkError,
            'isNetworkError',
            isTrue,
          ),
        ),
      );
    });

    test('getRates maps TimeoutException to a network error after both attempts', () async {
      final mockClient = MockClient((request) async {
        throw TimeoutException('timed out');
      });

      final ds = FastApiMarketRatesRemoteDataSource(client: mockClient);

      await expectLater(
        ds.getRates(accessToken: 'test_token'),
        throwsA(
          isA<MarketRatesException>().having(
            (e) => e.isNetworkError,
            'isNetworkError',
            isTrue,
          ),
        ),
      );
    });
  });

  group('Milestone 5 Step 9 — Repository Implementation Tests', () {
    test('MarketRatesRepositoryImpl delegates getRates and setRate to the data source', () async {
      final mockDs = _MockMarketRatesRemoteDataSource();
      mockDs.ratesToReturn = [sampleRiceA];

      final repository = MarketRatesRepositoryImpl(remoteDataSource: mockDs);
      final rows = await repository.getRates(accessToken: 'token');
      expect(rows.single, sampleRiceA);
      expect(mockDs.getRatesCallCount, 1);

      await repository.setRate(
        accessToken: 'token',
        cropType: 'Rice',
        grade: 'A',
        pricePerKg: 22.5,
        effectiveDate: '2026-09-28',
      );
      expect(mockDs.setRateCallCount, 1);
      expect(mockDs.setRatePayloads.single['price_per_kg'], 22.5);
    });
  });

  group('Milestone 5 Step 9 — Controller Unit & Flow Tests', () {
    late _MockMarketRatesRemoteDataSource mockDs;
    late MarketRatesRepository repository;
    late MarketRatesController controller;

    setUp(() {
      mockDs = _MockMarketRatesRemoteDataSource();
      mockDs.ratesToReturn = List.of(sampleRates);
      repository = MarketRatesRepositoryImpl(remoteDataSource: mockDs);
      controller = MarketRatesController(
        repository: repository,
        accessToken: 'test_token',
        role: UserRole.admin,
      );
    });

    test('loadRates loads dataset, clears error and stamps updatedAt', () async {
      await controller.loadRates();

      expect(controller.isLoading, isFalse);
      expect(controller.rates.length, 4);
      expect(controller.errorMessage, isNull);
      expect(controller.updatedAt, isNotNull);
      expect(controller.updatedLabel, startsWith('Updated '));
    });

    test('loadRates failure stores the typed error and keeps rates empty', () async {
      mockDs.getErrorToThrow = const MarketRatesServerException(
        message: 'Market feed unavailable',
      );

      await controller.loadRates();

      expect(controller.errorMessage, 'Market feed unavailable');
      expect(controller.rates, isEmpty);
      expect(controller.groups, isEmpty);
    });

    test('loadRates maps raw SocketException through ErrorSanitizer', () async {
      mockDs.getErrorToThrow = const SocketException('failed host lookup');

      await controller.loadRates();

      expect(controller.errorMessage, ErrorSanitizer.networkErrorMessage);
    });

    test('refreshRates toggles isRefreshing synchronously then settles', () async {
      final future = controller.refreshRates();
      expect(controller.isRefreshing, isTrue);

      await future;
      expect(controller.isRefreshing, isFalse);
      expect(controller.rates.length, 4);
    });

    test('setSearchQuery filters groups case-insensitively', () async {
      await controller.loadRates();
      expect(controller.groups.length, 3);

      controller.setSearchQuery('whe');
      expect(controller.groups.map((g) => g.cropType).toList(), ['Wheat']);

      controller.setSearchQuery('RICE');
      expect(controller.groups.single.cropType, 'Rice');
    });

    test('clearSearch restores every group', () async {
      await controller.loadRates();
      controller.setSearchQuery('wheat');
      expect(controller.groups.length, 1);

      controller.clearSearch();
      expect(controller.searchQuery, '');
      expect(controller.groups.length, 3);
    });

    test('groups keep alphabetical crops with A,B,C grade ordering', () async {
      await controller.loadRates();

      final crops = controller.groups.map((g) => g.cropType).toList();
      expect(crops, ['Maize', 'Rice', 'Wheat']);
      expect(
        controller.groups[1].rates.map((r) => r.grade).toList(),
        ['A', 'B'],
      );
    });

    test('canSetRate follows RBAC: Admin/Super Admin yes, Manager no', () {
      expect(
        MarketRatesController(
          repository: repository,
          accessToken: 't',
          role: UserRole.admin,
        ).canSetRate,
        isTrue,
      );
      expect(
        MarketRatesController(
          repository: repository,
          accessToken: 't',
          role: UserRole.superAdmin,
        ).canSetRate,
        isTrue,
      );
      expect(
        MarketRatesController(
          repository: repository,
          accessToken: 't',
          role: UserRole.manager,
        ).canSetRate,
        isFalse,
      );
    });

    test('setRates posts one request per filled grade then reloads the board', () async {
      await controller.loadRates();
      final loadsBefore = mockDs.getRatesCallCount;

      final result = await controller.setRates(
        cropType: 'Rice',
        prices: {'A': 22.5, 'B': 21.0, 'C': 19.5},
      );

      expect(result.succeeded, 3);
      expect(result.failed, 0);
      expect(result.errorMessage, isNull);
      expect(mockDs.setRateCallCount, 3);
      expect(mockDs.setRatePayloads.map((p) => p['grade']).toList(), [
        'A',
        'B',
        'C',
      ]);
      expect(mockDs.setRatePayloads.every((p) => p['crop_type'] == 'Rice'), isTrue);
      expect(
        mockDs.setRatePayloads.every(
          (p) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(p['effective_date'] as String),
        ),
        isTrue,
      );
      expect(mockDs.getRatesCallCount, loadsBefore + 1);
    });

    test('setRates submits only filled grades (empty grades are never sent)', () async {
      final result = await controller.setRates(
        cropType: 'Wheat',
        prices: {'A': 24.0},
      );

      expect(result.succeeded, 1);
      expect(result.failed, 0);
      expect(mockDs.setRateCallCount, 1);
      expect(mockDs.setRatePayloads.single['grade'], 'A');
    });

    test('setRates reports partial failure accurately and still reloads', () async {
      mockDs.setErrorToThrow = const MarketRatesValidationException(
        message: 'price_per_kg must be greater than 0',
      );
      mockDs.failOnGrade = 'B';
      final loadsBefore = mockDs.getRatesCallCount;

      final result = await controller.setRates(
        cropType: 'Rice',
        prices: {'A': 22.5, 'B': 21.0, 'C': 19.5},
      );

      expect(result.succeeded, 2);
      expect(result.failed, 1);
      expect(result.errorMessage, 'price_per_kg must be greater than 0');
      expect(mockDs.setRateCallCount, 3);
      expect(mockDs.getRatesCallCount, loadsBefore + 1);
    });

    test('setRates is blocked for Manager with permission message and zero requests', () async {
      final managerController = MarketRatesController(
        repository: repository,
        accessToken: 'test_token',
        role: UserRole.manager,
      );

      final result = await managerController.setRates(
        cropType: 'Rice',
        prices: {'A': 22.5},
      );

      expect(result.succeeded, 0);
      expect(result.failed, 0);
      expect(result.errorMessage, ErrorSanitizer.permissionDeniedMessage);
      expect(mockDs.setRateCallCount, 0);
    });

    test('setRates rejects an empty price map before any request', () async {
      final result = await controller.setRates(cropType: 'Rice', prices: {});

      expect(result.errorMessage, 'Enter at least one grade price.');
      expect(mockDs.setRateCallCount, 0);
    });

    test('setRates rejects an empty crop type before any request', () async {
      final result = await controller.setRates(
        cropType: '   ',
        prices: {'A': 22.5},
      );

      expect(result.errorMessage, 'Select a crop type.');
      expect(mockDs.setRateCallCount, 0);
    });
  });

  group('Milestone 5 Step 9 — UI & Widget Tests', () {
    late _MockMarketRatesRemoteDataSource mockDs;
    late MarketRatesController controller;

    setUp(() {
      mockDs = _MockMarketRatesRemoteDataSource();
      mockDs.ratesToReturn = List.of(sampleRates);
      controller = _buildController(mockDs: mockDs, role: UserRole.admin);
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MarketRatesScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('MarketRateCard renders crop, grade grid, ₹/quintal prices and footer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarketRateCard(
              group: MarketRateGroup.groupRates([sampleRiceA, sampleRiceB]).single,
            ),
          ),
        ),
      );

      expect(find.text('Rice'), findsOneWidget);
      expect(find.text('GRADE A'), findsOneWidget);
      expect(find.text('GRADE B'), findsOneWidget);
      expect(find.text('₹2,150'), findsOneWidget);
      expect(find.text('₹2,025'), findsOneWidget);
      expect(find.text('Rates per quintal'), findsOneWidget);
    });

    testWidgets('Edit action reveals the backend-required notice and never edits', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarketRateCard(
              group: MarketRateGroup.groupRates([sampleRiceA]).single,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('market-rate-edit-disabled')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Market Rate'), findsOneWidget);
      expect(
        find.text('Backend API required — to be supplied by Syed.'),
        findsOneWidget,
      );
      expect(find.byType(MarketRateCard), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Backend API required — to be supplied by Syed.'), findsNothing);
    });

    testWidgets('MarketRatesScreen renders header, search and cards for Admin', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpScreen(tester);

      expect(find.text('Live mandi prices'), findsOneWidget);
      expect(find.text('Market Rates'), findsOneWidget);
      expect(find.byKey(const ValueKey('market-rates-search')), findsOneWidget);
      expect(find.byKey(const ValueKey('market-rates-set-rate')), findsOneWidget);
      expect(find.byKey(const ValueKey('market-rates-updated-at')), findsOneWidget);
      expect(find.byKey(const ValueKey('market-rate-card-Rice')), findsOneWidget);
      expect(find.byKey(const ValueKey('market-rate-card-Wheat')), findsOneWidget);
      expect(find.byKey(const ValueKey('market-rate-card-Maize')), findsOneWidget);
    });

    testWidgets('Manager sees the board read-only with no Set Rate action', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final managerController = _buildController(mockDs: mockDs, role: UserRole.manager);
      await tester.pumpWidget(
        MaterialApp(
          home: MarketRatesScreen(controller: managerController, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('market-rates-set-rate')), findsNothing);
      expect(find.byKey(const ValueKey('market-rate-card-Rice')), findsOneWidget);
    });

    testWidgets('Client-side search filters cards and clearing restores them', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpScreen(tester);
      expect(find.byKey(const ValueKey('market-rate-card-Rice')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('market-rates-search')),
        'wheat',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('market-rate-card-Wheat')), findsOneWidget);
      expect(find.byKey(const ValueKey('market-rate-card-Rice')), findsNothing);

      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('market-rate-card-Rice')), findsOneWidget);
      expect(find.byKey(const ValueKey('market-rate-card-Wheat')), findsOneWidget);
      expect(find.byKey(const ValueKey('market-rate-card-Maize')), findsOneWidget);
    });

    testWidgets('No-match search renders the search empty state', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(const ValueKey('market-rates-search')),
        'zzz',
      );
      await tester.pumpAndSettle();

      expect(find.text('No Matching Crops'), findsOneWidget);
      expect(find.byKey(const ValueKey('market-rate-card-Rice')), findsNothing);
    });

    testWidgets('Empty dataset renders No Market Rates Configured', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      mockDs.ratesToReturn = [];

      await pumpScreen(tester);

      expect(find.text('No Market Rates Configured'), findsOneWidget);
      expect(find.byKey(const ValueKey('market-rates-set-rate')), findsOneWidget);
    });

    testWidgets('Load failure renders the error state with retry', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      mockDs.getErrorToThrow = const MarketRatesServerException(
        message: 'Market feed unavailable',
      );

      await pumpScreen(tester);

      expect(find.text('Unable to load content'), findsOneWidget);
      expect(find.text('Market feed unavailable'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('Pull-to-refresh reloads the board from the repository', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpScreen(tester);
      final loadsBefore = mockDs.getRatesCallCount;

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(mockDs.getRatesCallCount, greaterThan(loadsBefore));
    });

    testWidgets('Set Rate sheet opens with crop dropdown, three price fields and Save Rates', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('market-rates-set-rate')));
      await tester.pumpAndSettle();

      expect(find.text('Set New Rate'), findsOneWidget);
      expect(find.byKey(const ValueKey('set-rate-crop-dropdown')), findsOneWidget);
      expect(find.byKey(const ValueKey('set-rate-price-A')), findsOneWidget);
      expect(find.byKey(const ValueKey('set-rate-price-B')), findsOneWidget);
      expect(find.byKey(const ValueKey('set-rate-price-C')), findsOneWidget);
      expect(find.byKey(const ValueKey('set-rate-submit')), findsOneWidget);
      expect(find.text('Save Rates'), findsOneWidget);
    });

    testWidgets('Sheet validation requires a crop type', (tester) async {
      await openSheetHarness(tester, controller);

      await tester.tap(find.byKey(const ValueKey('set-rate-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Select a crop type.'), findsOneWidget);
      expect(mockDs.setRateCallCount, 0);
    });

    testWidgets('Sheet validation requires at least one grade price', (tester) async {
      await openSheetHarness(tester, controller);
      await selectCrop(tester, 'Rice');

      await tester.tap(find.byKey(const ValueKey('set-rate-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Enter at least one grade price.'), findsOneWidget);
      expect(mockDs.setRateCallCount, 0);
    });

    testWidgets('Sheet validation rejects non-numeric and non-positive prices', (tester) async {
      await openSheetHarness(tester, controller);
      await selectCrop(tester, 'Rice');

      await tester.enterText(find.byKey(const ValueKey('set-rate-price-A')), 'abc');
      await tester.tap(find.byKey(const ValueKey('set-rate-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid price for Grade A.'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('set-rate-price-A')), '0');
      await tester.tap(find.byKey(const ValueKey('set-rate-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text('Price for Grade A must be greater than 0.'),
        findsOneWidget,
      );
      expect(mockDs.setRateCallCount, 0);
    });

    testWidgets('Valid sheet submission posts only filled grades and closes the sheet', (tester) async {
      await openSheetHarness(tester, controller);
      await selectCrop(tester, 'Rice');

      await tester.enterText(find.byKey(const ValueKey('set-rate-price-A')), '22.5');
      await tester.tap(find.byKey(const ValueKey('set-rate-submit')));
      await tester.pumpAndSettle();

      expect(find.byType(SetRateSheet), findsNothing);
      expect(mockDs.setRateCallCount, 1);
      expect(mockDs.setRatePayloads.single['crop_type'], 'Rice');
      expect(mockDs.setRatePayloads.single['grade'], 'A');
      expect(mockDs.setRatePayloads.single['price_per_kg'], 22.5);
    });

    testWidgets('Admin Set Rate flow shows the success snackbar after persistence', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('market-rates-set-rate')));
      await tester.pumpAndSettle();

      await selectCrop(tester, 'Rice');
      await tester.enterText(find.byKey(const ValueKey('set-rate-price-A')), '22.5');
      await tester.tap(find.byKey(const ValueKey('set-rate-submit')));
      await tester.pumpAndSettle();

      expect(mockDs.setRateCallCount, 1);
      expect(find.text('Market rate set successfully'), findsOneWidget);
    });
  });

  group('Milestone 5 Step 9 — Responsive Layout Verification', () {
    final screenSizes = [
      const Size(320, 568),
      const Size(360, 640),
      const Size(412, 860),
      const Size(412, 960),
    ];

    for (final size in screenSizes) {
      testWidgets('MarketRatesScreen renders without overflow on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockDs = _MockMarketRatesRemoteDataSource();
        mockDs.ratesToReturn = List.of(sampleRates);
        final ctrl = _buildController(mockDs: mockDs, role: UserRole.admin);

        await tester.pumpWidget(
          MaterialApp(
            home: MarketRatesScreen(controller: ctrl, onBack: () {}),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(MarketRatesScreen), findsOneWidget);
      });
    }
  });

  group('Milestone 5 Step 9 — Shell Navigation Integration Tests', () {
    final mockSessionAdmin = AuthSession(
      accessToken: 'token_admin',
      refreshToken: 'refresh_admin',
      user: const AuthUser(
        id: 'admin-1',
        name: 'Super Admin',
        phone: '+91 99999 00000',
        role: UserRole.admin,
      ),
    );

    final mockSessionManager = AuthSession(
      accessToken: 'token_manager',
      refreshToken: 'refresh_manager',
      user: const AuthUser(
        id: 'manager-1',
        name: 'Branch Manager',
        phone: '+91 88888 00000',
        role: UserRole.manager,
      ),
    );

    testWidgets('AdminShell routes to MarketRatesScreen with Set Rate visible', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = _MockMarketRatesRemoteDataSource();
      mockDs.ratesToReturn = [sampleRiceA];
      final marketRatesCtrl = MarketRatesController(
        repository: MarketRatesRepositoryImpl(remoteDataSource: mockDs),
        accessToken: 'token_admin',
        role: UserRole.admin,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(
            session: mockSessionAdmin,
            onLogout: () {},
            marketRatesController: marketRatesCtrl,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerItem = find.descendant(
        of: find.byType(CustomDrawer),
        matching: find.text('Market Rates'),
      );
      expect(drawerItem, findsOneWidget);
      await tester.tap(drawerItem);
      await tester.pumpAndSettle();

      expect(find.byType(MarketRatesScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('market-rates-set-rate')), findsOneWidget);
      expect(find.byKey(const ValueKey('market-rate-card-Rice')), findsOneWidget);
    });

    testWidgets('ManagerShell routes to MarketRatesScreen without Set Rate', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = _MockMarketRatesRemoteDataSource();
      mockDs.ratesToReturn = [sampleRiceA];
      final marketRatesCtrl = MarketRatesController(
        repository: MarketRatesRepositoryImpl(remoteDataSource: mockDs),
        accessToken: 'token_manager',
        role: UserRole.manager,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ManagerShell(
            session: mockSessionManager,
            onLogout: () {},
            marketRatesController: marketRatesCtrl,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerItem = find.descendant(
        of: find.byType(CustomDrawer),
        matching: find.text('Market Rates'),
      );
      expect(drawerItem, findsOneWidget);
      await tester.tap(drawerItem);
      await tester.pumpAndSettle();

      expect(find.byType(MarketRatesScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('market-rates-set-rate')), findsNothing);
      expect(find.byKey(const ValueKey('market-rate-card-Rice')), findsOneWidget);
    });
  });
}
