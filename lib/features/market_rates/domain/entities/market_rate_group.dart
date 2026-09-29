import 'market_rate_item.dart';

/// Rates of a single crop, sorted by grade A -> B -> C.
class MarketRateGroup {
  final String cropType;
  final List<MarketRateItem> rates;

  const MarketRateGroup({
    required this.cropType,
    required this.rates,
  });

  /// Canonical grade ordering used by the approved HTML grade grid.
  static const List<String> gradeOrder = ['A', 'B', 'C'];

  /// Groups [items] by crop (case-insensitive search on [query]) and sorts
  /// crops alphabetically with grades A, B, C inside each group.
  static List<MarketRateGroup> groupRates(
    List<MarketRateItem> items, {
    String? query,
  }) {
    var filtered = items;
    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      filtered = items
          .where((rate) => rate.cropType.toLowerCase().contains(q))
          .toList();
    }

    final byCrop = <String, List<MarketRateItem>>{};
    for (final rate in filtered) {
      byCrop.putIfAbsent(rate.cropType, () => []).add(rate);
    }

    final groups = byCrop.entries.map((entry) {
      final sorted = [...entry.value]..sort(_compareRates);
      return MarketRateGroup(cropType: entry.key, rates: sorted);
    }).toList()
      ..sort((a, b) => a.cropType.toLowerCase().compareTo(b.cropType.toLowerCase()));

    return groups;
  }

  static int _compareRates(MarketRateItem a, MarketRateItem b) {
    final gradeA = gradeOrder.indexOf(a.grade);
    final gradeB = gradeOrder.indexOf(b.grade);
    final orderA = gradeA == -1 ? gradeOrder.length : gradeA;
    final orderB = gradeB == -1 ? gradeOrder.length : gradeB;
    final byGrade = orderA.compareTo(orderB);
    if (byGrade != 0) return byGrade;
    if (a.grade != b.grade) {
      return a.grade.toLowerCase().compareTo(b.grade.toLowerCase());
    }
    // Duplicate rows for the same grade: latest effective date first.
    return (b.effectiveDate ?? '').compareTo(a.effectiveDate ?? '');
  }
}
