import 'package:agriflow_admin/core/utils/app_dates.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_item.dart';

/// Immutable, fully-formatted inputs for the downloadable seed-purchase
/// invoice PDF (client-side export — no backend involvement).
class SeedInvoiceData {
  final String invoiceNumber;
  final String orderDate;
  final String farmerName;
  final String farmerPhone;
  final String seedName;
  final String seedVariety;
  final String quantity;
  final String pricePerKg;
  final String totalAmount;
  final String paymentStatus;
  final String fileName;

  const SeedInvoiceData({
    required this.invoiceNumber,
    required this.orderDate,
    required this.farmerName,
    required this.farmerPhone,
    required this.seedName,
    required this.seedVariety,
    required this.quantity,
    required this.pricePerKg,
    required this.totalAmount,
    required this.paymentStatus,
    required this.fileName,
  });

  factory SeedInvoiceData.fromItem(SeedPurchaseItem item) {
    final number = item.invoiceNumber ??
        (item.id.length > 8 ? item.id.substring(0, 8) : item.id);
    final safeName = number.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return SeedInvoiceData(
      invoiceNumber: number,
      orderDate: item.createdAt != null
          ? AppDates.dateTimeLabel(item.createdAt!.toLocal())
          : '-',
      farmerName: item.displayName,
      farmerPhone: item.displayPhone,
      seedName: item.displaySeed,
      seedVariety: item.displayVariety,
      quantity:
          '${item.quantityKg.toStringAsFixed(1)} kg (${(item.quantityKg / 100).toStringAsFixed(2)} Qtl)',
      pricePerKg: '₹${item.pricePerKg.toStringAsFixed(2)}',
      totalAmount: '₹${item.totalAmount.toStringAsFixed(2)}',
      paymentStatus: item.paymentStatus,
      fileName: 'invoice_$safeName.pdf',
    );
  }
}
