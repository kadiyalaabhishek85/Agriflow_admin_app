import 'package:intl/intl.dart';

import '../exceptions/market_rates_exception.dart';

/// Single market rate row as returned by `MarketRatePublic`
/// (`id`, `crop_type`, `grade`, `price_per_kg`, `effective_date`).
///
/// The domain value stays in `pricePerKg` (backend unit, e.g. `21.50`).
/// Quintal conversion happens only at presentation time via
/// [displayPricePerQtl] — the backend price is never modified.
class MarketRateItem {
  final String id;
  final String cropType;

  /// Grain grade: `A`, `B` or `C` (normalised to upper case).
  final String grade;
  final double pricePerKg;

  /// Raw `effective_date` as `YYYY-MM-DD` (nullable).
  final String? effectiveDate;

  const MarketRateItem({
    required this.id,
    required this.cropType,
    required this.grade,
    required this.pricePerKg,
    this.effectiveDate,
  });

  factory MarketRateItem.fromJson(Map<String, dynamic> json) {
    return MarketRateItem(
      id: json['id']?.toString() ?? '',
      cropType: json['crop_type']?.toString() ?? '',
      grade: _parseGrade(json['grade']),
      pricePerKg: _parsePrice(json['price_per_kg']),
      effectiveDate: json['effective_date']?.toString(),
    );
  }

  static String _parseGrade(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) {
      throw const MarketRatesException(
        message: 'Market rate data is invalid.',
      );
    }
    return text.toUpperCase();
  }

  static double _parsePrice(dynamic raw) {
    if (raw is num) return raw.toDouble();
    final text = raw?.toString().trim() ?? '';
    final parsed = double.tryParse(text);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      throw const MarketRatesException(
        message: 'Market rate data is invalid.',
      );
    }
    return parsed;
  }

  /// Parsed [effectiveDate] (`YYYY-MM-DD`), or null when absent/unparsable.
  DateTime? get effectiveDateTime {
    final raw = effectiveDate;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Price in the backend unit (₹ per kg), unmodified.
  double get displayPricePerKg => pricePerKg;

  /// Presentation conversion only: ₹ per quintal = price_per_kg * 100.
  double get displayPricePerQtl => pricePerKg * 100;

  /// `₹21.50` — backend value formatted for display.
  String get displayPricePerKgLabel =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)
          .format(displayPricePerKg);

  /// `₹2,150` — quintal conversion formatted for display (rounds away
  /// floating-point artefacts of the `* 100` conversion).
  String get displayPricePerQtlLabel =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
          .format(displayPricePerQtl);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketRateItem &&
          other.id == id &&
          other.cropType == cropType &&
          other.grade == grade &&
          other.pricePerKg == pricePerKg &&
          other.effectiveDate == effectiveDate;

  @override
  int get hashCode =>
      Object.hash(id, cropType, grade, pricePerKg, effectiveDate);

  @override
  String toString() =>
      'MarketRateItem($cropType Grade $grade ₹$pricePerKg/kg)';
}
