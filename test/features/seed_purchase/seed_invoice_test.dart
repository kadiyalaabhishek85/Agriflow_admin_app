import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_item.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/services/seed_invoice_data.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/services/seed_invoice_downloader.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/services/seed_invoice_pdf_builder.dart';
import 'package:agriflow_admin/features/seed_purchase/presentation/widgets/seed_purchase_detail_sheet.dart';

SeedPurchaseItem _item({
  String id = 'purchase-1',
  String? invoiceNumber = 'INV-0042',
  String paymentStatus = 'paid',
}) {
  return SeedPurchaseItem(
    id: id,
    farmerId: 'farmer-1',
    seedId: 'seed-1',
    quantityKg: 250,
    pricePerKg: 48.5,
    totalAmount: 12125,
    paymentStatus: paymentStatus,
    invoiceNumber: invoiceNumber,
    createdAt: DateTime.utc(2026, 9, 26, 10, 30),
    enrichedFarmerName: 'Asha Rao',
    enrichedFarmerPhone: '9876543210',
    enrichedSeedName: 'Sahyadri Red',
    enrichedSeedVariety: 'Rubi',
  );
}

class _FakeInvoiceDownloader implements InvoiceDownloader {
  final InvoiceDownloadResult result;
  final Duration delay;
  int calls = 0;
  SeedInvoiceData? lastData;

  _FakeInvoiceDownloader(this.result, {this.delay = Duration.zero});

  @override
  Future<InvoiceDownloadResult> download({required SeedInvoiceData data}) async {
    calls += 1;
    lastData = data;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return result;
  }
}

void main() {
  group('M11 E — SeedInvoiceData.fromItem', () {
    test('maps enriched row fields, formatted values and invoice file name', () {
      final data = SeedInvoiceData.fromItem(_item());

      expect(data.invoiceNumber, 'INV-0042');
      expect(data.fileName, 'invoice_INV-0042.pdf');
      expect(data.farmerName, 'Asha Rao');
      expect(data.farmerPhone, '9876543210');
      expect(data.seedName, 'Sahyadri Red');
      expect(data.seedVariety, 'Rubi');
      expect(data.quantity, '250.0 kg (2.50 Qtl)');
      expect(data.pricePerKg, '₹48.50');
      expect(data.totalAmount, '₹12125.00');
      expect(data.paymentStatus, 'paid');
      expect(data.orderDate, isNot('-'));
    });

    test('falls back to the raw id when the invoice number is missing', () {
      final data = SeedInvoiceData.fromItem(
        _item(id: 'a-very-long-purchase-id', invoiceNumber: null),
      );
      expect(data.invoiceNumber, 'a-very-l');
      expect(data.fileName, 'invoice_a-very-l.pdf');
    });
  });

  group('M11 E — buildSeedInvoicePdf', () {
    test('renders a non-empty PDF containing the invoice payload', () async {
      final font = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final fontBytes = font.buffer.asUint8List(font.offsetInBytes, font.lengthInBytes);

      final bytes = await buildSeedInvoicePdf(
        SeedInvoiceData.fromItem(_item()),
        fontBytes: fontBytes,
        compress: false,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });

  group('M11 E — AndroidInvoiceDownloader seams', () {
    SeedInvoiceData data() => SeedInvoiceData.fromItem(_item());

    test('success path returns fixed message and saved location', () async {
      late SeedInvoiceData seen;
      final downloader = AndroidInvoiceDownloader(
        buildPdf: (d, fontBytes) async {
          seen = d;
          return Uint8List.fromList([37, 80, 68, 70]);
        },
        saveFile: (bytes, fileName) async => '/storage/$fileName',
        loadFont: () async => Uint8List.fromList([1, 2, 3]),
      );

      final result = await downloader.download(data: data());

      expect(result.success, isTrue);
      expect(result.message, InvoiceMessages.downloadSuccess);
      expect(result.location, '/storage/invoice_INV-0042.pdf');
      expect(seen.invoiceNumber, 'INV-0042');
    });

    test('builder failure returns pdfFailure and never touches the file system', () async {
      var saved = false;
      final downloader = AndroidInvoiceDownloader(
        buildPdf: (d, fontBytes) async => throw Exception('bad font'),
        saveFile: (bytes, fileName) async {
          saved = true;
          return '/storage/$fileName';
        },
        loadFont: () async => Uint8List.fromList([1, 2, 3]),
      );

      final result = await downloader.download(data: data());

      expect(result.success, isFalse);
      expect(result.message, InvoiceMessages.pdfFailure);
      expect(saved, isFalse);
    });

    test('font loader failure returns pdfFailure', () async {
      final downloader = AndroidInvoiceDownloader(
        buildPdf: (d, fontBytes) async => Uint8List.fromList([37, 80]),
        saveFile: (bytes, fileName) async => '/storage/$fileName',
        loadFont: () async => throw Exception('asset missing'),
      );

      final result = await downloader.download(data: data());

      expect(result.success, isFalse);
      expect(result.message, InvoiceMessages.pdfFailure);
    });

    test('null from the SAF picker maps to the cancelled message', () async {
      final downloader = AndroidInvoiceDownloader(
        buildPdf: (d, fontBytes) async => Uint8List.fromList([37, 80, 68, 70]),
        saveFile: (bytes, fileName) async => null,
        loadFont: () async => Uint8List.fromList([1, 2, 3]),
      );

      final result = await downloader.download(data: data());

      expect(result.success, isFalse);
      expect(result.message, InvoiceMessages.cancelled);
    });

    test('permission PlatformException maps to the permissionDenied message', () async {
      final downloader = AndroidInvoiceDownloader(
        buildPdf: (d, fontBytes) async => Uint8List.fromList([37, 80, 68, 70]),
        saveFile: (bytes, fileName) async =>
            throw PlatformException(code: 'permission_denied', message: 'raw'),
        loadFont: () async => Uint8List.fromList([1, 2, 3]),
      );

      final result = await downloader.download(data: data());

      expect(result.success, isFalse);
      expect(result.message, InvoiceMessages.permissionDenied);
      expect(result.message.contains('raw'), isFalse);
    });

    test('non-permission PlatformException maps to the saveFailure message', () async {
      final downloader = AndroidInvoiceDownloader(
        buildPdf: (d, fontBytes) async => Uint8List.fromList([37, 80, 68, 70]),
        saveFile: (bytes, fileName) async =>
            throw PlatformException(code: 'io_error', message: 'disk exploded'),
        loadFont: () async => Uint8List.fromList([1, 2, 3]),
      );

      final result = await downloader.download(data: data());

      expect(result.success, isFalse);
      expect(result.message, InvoiceMessages.saveFailure);
      expect(result.message.contains('disk exploded'), isFalse);
    });

    test('generic save failure maps to the saveFailure message', () async {
      final downloader = AndroidInvoiceDownloader(
        buildPdf: (d, fontBytes) async => Uint8List.fromList([37, 80, 68, 70]),
        saveFile: (bytes, fileName) async => throw StateError('boom'),
        loadFont: () async => Uint8List.fromList([1, 2, 3]),
      );

      final result = await downloader.download(data: data());

      expect(result.success, isFalse);
      expect(result.message, InvoiceMessages.saveFailure);
    });
  });

  group('M11 E — SeedPurchaseDetailSheet invoice action', () {
    Widget wrap(SeedPurchaseItem item, InvoiceDownloader? downloader) {
      return MaterialApp(
        home: Scaffold(
          body: SeedPurchaseDetailSheet(
            item: item,
            isActionInFlight: false,
            onApprove: () {},
            onReject: () {},
            downloader: downloader,
          ),
        ),
      );
    }

    Future<void> drainToast(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pumpAndSettle();
    }

    testWidgets('paid row shows Download invoice without approve/reject', (tester) async {
      await tester.pumpWidget(wrap(_item(), null));

      expect(find.text('Download invoice'), findsOneWidget);
      expect(find.text('Approve & Mark Paid'), findsNothing);
      expect(find.text('Reject Request'), findsNothing);

      await drainToast(tester);
    });

    testWidgets('pending row keeps approve/reject and still offers invoice download', (tester) async {
      await tester.pumpWidget(wrap(_item(paymentStatus: 'pending'), null));

      expect(find.text('Approve & Mark Paid'), findsOneWidget);
      expect(find.text('Reject Request'), findsOneWidget);
      expect(find.text('Download invoice'), findsOneWidget);

      await drainToast(tester);
    });

    testWidgets('tap downloads through the seam and shows the fixed success toast',
        (tester) async {
      final fake = _FakeInvoiceDownloader(
        const InvoiceDownloadResult(
          success: true,
          message: InvoiceMessages.downloadSuccess,
          location: '/storage/invoice_INV-0042.pdf',
        ),
        delay: const Duration(milliseconds: 50),
      );
      await tester.pumpWidget(wrap(_item(), fake));

      await tester.tap(find.text('Download invoice'));
      await tester.pump();

      expect(fake.calls, 1);
      expect(find.text('Preparing invoice…'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.text('Download invoice'), findsOneWidget);
      expect(find.text(InvoiceMessages.downloadSuccess), findsOneWidget);
      expect(fake.lastData?.invoiceNumber, 'INV-0042');

      await drainToast(tester);
    });

    testWidgets('failure result surfaces the sanitized failure toast', (tester) async {
      final fake = _FakeInvoiceDownloader(
        const InvoiceDownloadResult(
          success: false,
          message: InvoiceMessages.saveFailure,
        ),
      );
      await tester.pumpWidget(wrap(_item(), fake));

      await tester.tap(find.text('Download invoice'));
      await tester.pump();
      await tester.pump();

      expect(fake.calls, 1);
      expect(find.text(InvoiceMessages.saveFailure), findsOneWidget);

      await drainToast(tester);
    });

    testWidgets('duplicate taps while in flight start a single download', (tester) async {
      final fake = _FakeInvoiceDownloader(
        const InvoiceDownloadResult(
          success: true,
          message: InvoiceMessages.downloadSuccess,
        ),
        delay: const Duration(milliseconds: 200),
      );
      await tester.pumpWidget(wrap(_item(), fake));

      await tester.tap(find.text('Download invoice'));
      await tester.pump();
      await tester.tap(find.text('Preparing invoice…'), warnIfMissed: false);
      await tester.pump();

      expect(fake.calls, 1);

      await tester.pump(const Duration(milliseconds: 300));
      await drainToast(tester);
    });
  });
}
