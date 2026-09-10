import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency_rate.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rate_trend.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fixtures.dart';

/// These are the highest-value tests in the suite: the inversion and the
/// direction of the EGP trend are the two places where a plausible-looking
/// mistake produces a screen full of confidently wrong numbers.
void main() {
  group('CurrencyRate.fromEgpQuotes', () {
    test('inverts the API quote into EGP per foreign unit', () {
      final rate = CurrencyRate.fromEgpQuotes(
        currency: Currency.usd,
        unitsPerEgp: 0.02,
        asOf: Fixtures.today,
      );

      // 1 EGP = 0.02 USD  =>  1 USD = 50 EGP
      expect(rate.egpPerUnit, 50);
    });

    test('matches the worked example from the API docs', () {
      final rate = CurrencyRate.fromEgpQuotes(
        currency: Currency.usd,
        unitsPerEgp: 0.019227,
        asOf: Fixtures.today,
      );

      expect(rate.egpPerUnit, closeTo(52.01, 0.01));
    });

    test('inverts the previous quote too', () {
      final rate = CurrencyRate.fromEgpQuotes(
        currency: Currency.usd,
        unitsPerEgp: 0.02,
        previousUnitsPerEgp: 0.025,
        asOf: Fixtures.today,
        previousAsOf: Fixtures.yesterday,
      );

      expect(rate.previousEgpPerUnit, 40);
    });

    test('yields 0 rather than infinity for a zero quote', () {
      // A corrupt payload must not put `Infinity` into the chart or the
      // formatters.
      final rate = CurrencyRate.fromEgpQuotes(
        currency: Currency.usd,
        unitsPerEgp: 0,
        asOf: Fixtures.today,
      );

      expect(rate.egpPerUnit, 0);
      expect(rate.egpPerUnit.isFinite, isTrue);
    });
  });

  group('daily change', () {
    test('is null when there is no previous quote', () {
      final rate = Fixtures.usdRate(previousEgpPerUnit: null);

      expect(rate.hasChange, isFalse);
      expect(rate.absoluteChange, isNull);
      expect(rate.percentageChange, isNull);
    });

    test('computes the absolute delta in EGP', () {
      final rate = Fixtures.usdRate(egpPerUnit: 50, previousEgpPerUnit: 40);

      expect(rate.absoluteChange, 10);
    });

    test('computes the percentage against the previous quote', () {
      final rate = Fixtures.usdRate(egpPerUnit: 50, previousEgpPerUnit: 40);

      expect(rate.percentageChange, 25);
    });

    test('is null rather than infinite when the previous quote was zero', () {
      final rate = Fixtures.usdRate(egpPerUnit: 50, previousEgpPerUnit: 0);

      expect(rate.percentageChange, isNull);
    });
  });

  group('trend is expressed from the pound\'s point of view', () {
    test('a rising EGP-per-unit rate means the pound got WEAKER', () {
      // 40 -> 50 EGP per USD: it now costs more pounds to buy a dollar.
      final rate = Fixtures.usdRate(egpPerUnit: 50, previousEgpPerUnit: 40);

      expect(rate.trend, RateTrend.egpWeaker);
      expect(rate.trend.isWeaker, isTrue);
    });

    test('a falling EGP-per-unit rate means the pound got STRONGER', () {
      final rate = Fixtures.usdRate(egpPerUnit: 40, previousEgpPerUnit: 50);

      expect(rate.trend, RateTrend.egpStronger);
    });

    test('is unchanged when there is nothing to compare against', () {
      final rate = Fixtures.usdRate(previousEgpPerUnit: null);

      expect(rate.trend, RateTrend.unchanged);
    });

    test('treats sub-epsilon float noise as unchanged', () {
      final rate = Fixtures.usdRate(
        egpPerUnit: 50,
        previousEgpPerUnit: 50 - 1e-9,
      );

      expect(rate.trend, RateTrend.unchanged);
    });
  });

  group('Currency', () {
    test('exposes the API response key in lower case', () {
      expect(Currency.usd.responseKey, 'usd');
      expect(Currency.jpy.responseKey, 'jpy');
    });

    test('labels the pair against EGP', () {
      expect(Currency.gbp.pairLabel, 'GBP/EGP');
    });

    test('resolves codes case-insensitively', () {
      expect(Currency.fromCode('eur'), Currency.eur);
      expect(Currency.fromCode('EUR'), Currency.eur);
    });

    test('returns null for a currency we do not track', () {
      expect(Currency.fromCode('aed'), isNull);
    });

    test('tracks exactly the five currencies in the spec', () {
      expect(Currency.values.map((currency) => currency.code), [
        'USD',
        'EUR',
        'GBP',
        'SAR',
        'JPY',
      ]);
    });
  });
}
