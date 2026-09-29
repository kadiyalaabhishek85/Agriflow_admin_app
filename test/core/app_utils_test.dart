import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/core/utils/app_dates.dart';
import 'package:agriflow_admin/core/utils/app_initials.dart';

void main() {
  group('AppDates.dayMonthYear (flutter-03 rec 12)', () {
    test('Formats ISO date as zero-padded day month year', () {
      expect(AppDates.dayMonthYear('2026-09-28'), '28 Sep 2026');
      expect(AppDates.dayMonthYear('2026-09-05'), '05 Sep 2026');
      expect(AppDates.dayMonthYear('2026-01-01'), '01 Jan 2026');
    });

    test('Parses full ISO timestamp and space-separated datetime', () {
      expect(AppDates.dayMonthYear('2026-09-28T10:32:00Z'), '28 Sep 2026');
      expect(AppDates.dayMonthYear('2026-09-28 10:32:00'), '28 Sep 2026');
    });

    test('Null or empty input returns caller fallback', () {
      expect(AppDates.dayMonthYear(null), 'Not set');
      expect(AppDates.dayMonthYear(''), 'Not set');
      expect(AppDates.dayMonthYear('   '), 'Not set');
      expect(AppDates.dayMonthYear(null, fallback: 'Date TBD'), 'Date TBD');
    });

    test('Unparseable non-empty input passes through unchanged', () {
      expect(AppDates.dayMonthYear('not-a-date'), 'not-a-date');
      expect(AppDates.dayMonthYear('TBD by farmer'), 'TBD by farmer');
    });

    test('dayMonthYearOf formats a DateTime', () {
      expect(AppDates.dayMonthYearOf(DateTime(2026, 9, 5)), '05 Sep 2026');
      expect(AppDates.dayMonthYearOf(DateTime(2026, 12, 31)), '31 Dec 2026');
    });
  });

  group('AppDates.isoDateTimeLabel / dateTimeLabel (Event Logs format)', () {
    test('Formats ISO timestamp as "28 Sep 2026, 10:32" with 24h clock', () {
      expect(
        AppDates.isoDateTimeLabel('2026-09-28T10:32:00'),
        '28 Sep 2026, 10:32',
      );
      expect(
        AppDates.isoDateTimeLabel('2026-09-28T00:05:00'),
        '28 Sep 2026, 00:05',
      );
    });

    test('dateTimeLabel pads hour and minute', () {
      expect(
        AppDates.dateTimeLabel(DateTime(2026, 1, 2, 3, 4)),
        '02 Jan 2026, 03:04',
      );
      expect(
        AppDates.dateTimeLabel(DateTime(2026, 9, 28, 10, 32)),
        '28 Sep 2026, 10:32',
      );
    });

    test('Null or empty input returns em dash fallback', () {
      expect(AppDates.isoDateTimeLabel(null), '—');
      expect(AppDates.isoDateTimeLabel(''), '—');
      expect(AppDates.isoDateTimeLabel(null, fallback: 'Created'), 'Created');
    });

    test('Unparseable non-empty input passes through unchanged', () {
      expect(AppDates.isoDateTimeLabel('yesterday'), 'yesterday');
    });
  });

  group('AppDates.numericDate (invoice cards)', () {
    test('Formats as dd/MM/yyyy with zero padding', () {
      expect(AppDates.numericDate(DateTime(2026, 9, 5)), '05/09/2026');
      expect(AppDates.numericDate(DateTime(2026, 12, 31)), '31/12/2026');
    });
  });

  group('AppInitials (flutter-03 rec 11)', () {
    test('Two-word name returns first letters of first two words', () {
      expect(AppInitials.of('Rahul Nair'), 'RN');
      expect(AppInitials.of('Anil Kumar'), 'AK');
      expect(AppInitials.of('rahul nair'), 'RN');
    });

    test('Single word returns its first letter', () {
      expect(AppInitials.of('Rahul'), 'R');
      expect(AppInitials.of('suresh'), 'S');
    });

    test('Non-alphabetic characters are stripped before splitting', () {
      expect(AppInitials.of('Mary-Jane O\'Neil'), 'MJ');
      expect(AppInitials.of('Rahul (Nair)'), 'RN');
      expect(AppInitials.of('O\'Neil'), 'ON');
    });

    test('Three-or-more words use the first two words only', () {
      expect(AppInitials.of('A B C'), 'AB');
      expect(AppInitials.of('Rahul K Nair'), 'RK');
    });

    test('Null, empty, whitespace or symbol-only input uses fallback', () {
      expect(AppInitials.of(null), 'F');
      expect(AppInitials.of(''), 'F');
      expect(AppInitials.of('   '), 'F');
      expect(AppInitials.of('!!!'), 'F');
      expect(AppInitials.of(null, fallback: '?'), '?');
      expect(AppInitials.of('!!!', fallback: 'TX'), 'TX');
    });
  });
}
