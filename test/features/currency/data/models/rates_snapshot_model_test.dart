import 'package:currency_exchange_tracker/core/error/exceptions.dart';
import 'package:currency_exchange_tracker/features/currency/data/models/rates_snapshot_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  group('RatesSnapshotModel.fromJson', () {
    test('reads the date and the quote map', () {
      final model = RatesSnapshotModel.fromJson(Fixtures.latestJson());

      expect(model.date, DateTime(2026, 9, 9));
      expect(model.quoteFor('usd'), 0.02);
    });

    test('keeps every currency in the payload, not just the tracked five', () {
      // The feed returns 200+ currencies. Filtering at parse time would make
      // the cached payload lossy if the tracked set later grows.
      final model = RatesSnapshotModel.fromJson({
        'date': '2026-09-09',
        'egp': {'usd': 0.02, 'aed': 0.07, 'xyz': 1.5},
      });

      expect(model.quotes.keys, containsAll(['usd', 'aed', 'xyz']));
    });

    test('looks up quotes case-insensitively', () {
      final model = RatesSnapshotModel.fromJson({
        'date': '2026-09-09',
        'egp': {'USD': 0.02},
      });

      expect(model.quoteFor('usd'), 0.02);
    });

    test('coerces integer quotes to double', () {
      final model = RatesSnapshotModel.fromJson({
        'date': '2026-09-09',
        'egp': {'jpy': 3},
      });

      expect(model.quoteFor('jpy'), 3.0);
    });

    test('skips null and non-numeric quotes instead of failing', () {
      // Delisted tokens occasionally come back as null; one bad entry must not
      // cost us the other 200.
      final model = RatesSnapshotModel.fromJson({
        'date': '2026-09-09',
        'egp': {'usd': 0.02, 'dead': null, 'weird': true},
      });

      expect(model.quotes, {'usd': 0.02});
    });

    test('throws ParsingException when the date is missing', () {
      expect(
        () => RatesSnapshotModel.fromJson({
          'egp': {'usd': 0.02},
        }),
        throwsA(isA<ParsingException>()),
      );
    });

    test('throws ParsingException when the base key is missing', () {
      expect(
        () => RatesSnapshotModel.fromJson({'date': '2026-09-09'}),
        throwsA(isA<ParsingException>()),
      );
    });

    test('throws ParsingException when the date is unparseable', () {
      expect(
        () => RatesSnapshotModel.fromJson({
          'date': 'not-a-date',
          'egp': {'usd': 0.02},
        }),
        throwsA(isA<ParsingException>()),
      );
    });

    test('throws ParsingException when every quote was unusable', () {
      expect(
        () => RatesSnapshotModel.fromJson({
          'date': '2026-09-09',
          'egp': {'dead': null},
        }),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('cache round-trip', () {
    test('survives toJson/fromCacheJson unchanged', () {
      final original = Fixtures.latestSnapshot();

      final restored = RatesSnapshotModel.fromCacheJson(original.toJson());

      expect(restored, original);
    });

    test('throws CacheException on a corrupt cache document', () {
      expect(
        () => RatesSnapshotModel.fromCacheJson({'date': 'garbage'}),
        throwsA(isA<CacheException>()),
      );
    });
  });
}
