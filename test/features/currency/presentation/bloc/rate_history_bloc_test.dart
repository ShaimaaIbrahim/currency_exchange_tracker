import 'package:bloc_test/bloc_test.dart';
import 'package:currency_exchange_tracker/core/error/failures.dart';
import 'package:currency_exchange_tracker/core/utils/result.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/currency/domain/usecases/get_rate_history.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/rate_history/rate_history_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';

class _MockGetRateHistory extends Mock implements GetRateHistory {}

void main() {
  late _MockGetRateHistory getRateHistory;

  setUpAll(
    () => registerFallbackValue(
      const GetRateHistoryParams(currency: Currency.usd),
    ),
  );

  setUp(() => getRateHistory = _MockGetRateHistory());

  RateHistoryBloc buildBloc() =>
      RateHistoryBloc(getRateHistory: getRateHistory);

  void whenSucceeds({RateHistory? history}) {
    when(() => getRateHistory(any()))
        .thenAnswer((_) async => Ok(history ?? Fixtures.history()));
  }

  group('RateHistoryRequested', () {
    blocTest<RateHistoryBloc, RateHistoryState>(
      'emits loading then success with a plottable series',
      setUp: whenSucceeds,
      build: buildBloc,
      act: (bloc) => bloc.add(const RateHistoryRequested(Currency.usd)),
      expect: () => [
        isA<RateHistoryState>()
            .having((s) => s.status, 'status', RateHistoryStatus.loading)
            .having((s) => s.currency, 'currency', Currency.usd),
        isA<RateHistoryState>()
            .having((s) => s.status, 'status', RateHistoryStatus.success)
            .having((s) => s.isPlottable, 'isPlottable', isTrue),
      ],
    );

    blocTest<RateHistoryBloc, RateHistoryState>(
      'passes the tapped currency through to the use case',
      setUp: whenSucceeds,
      build: buildBloc,
      act: (bloc) => bloc.add(const RateHistoryRequested(Currency.jpy)),
      verify: (_) {
        verify(
          () => getRateHistory(
            const GetRateHistoryParams(currency: Currency.jpy),
          ),
        ).called(1);
      },
    );

    blocTest<RateHistoryBloc, RateHistoryState>(
      'emits a failure state the chart can render inline',
      setUp: () =>
          when(() => getRateHistory(any()))
              .thenAnswer((_) async => const Err<RateHistory>(NoDataFailure())),
      build: buildBloc,
      act: (bloc) => bloc.add(const RateHistoryRequested(Currency.eur)),
      expect: () => [
        isA<RateHistoryState>().having(
          (s) => s.status,
          'status',
          RateHistoryStatus.loading,
        ),
        isA<RateHistoryState>()
            .having((s) => s.status, 'status', RateHistoryStatus.failure)
            .having((s) => s.failure, 'failure', isA<NoDataFailure>())
            // The currency is retained so `Retry` needs no payload.
            .having((s) => s.currency, 'currency', Currency.eur),
      ],
    );

    blocTest<RateHistoryBloc, RateHistoryState>(
      'abandons an in-flight fetch when the currency changes',
      setUp: () {
        when(() => getRateHistory(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return Ok(Fixtures.history());
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const RateHistoryRequested(Currency.usd));
        // Yield so the USD request is in flight before GBP arrives.
        await Future<void>.delayed(const Duration(milliseconds: 5));
        bloc.add(const RateHistoryRequested(Currency.gbp));
        await Future<void>.delayed(const Duration(milliseconds: 40));
      },
      // `restartable` means the USD response can never overwrite the GBP one.
      expect: () => [
        isA<RateHistoryState>().having(
          (s) => s.currency,
          'currency',
          Currency.usd,
        ),
        isA<RateHistoryState>().having(
          (s) => s.currency,
          'currency',
          Currency.gbp,
        ),
        isA<RateHistoryState>()
            .having((s) => s.status, 'status', RateHistoryStatus.success)
            .having((s) => s.currency, 'currency', Currency.gbp),
      ],
    );
  });

  group('RateHistoryRetried', () {
    blocTest<RateHistoryBloc, RateHistoryState>(
      'reuses the currency already in state',
      setUp: whenSucceeds,
      build: buildBloc,
      seed: () => const RateHistoryState(
        status: RateHistoryStatus.failure,
        currency: Currency.sar,
        failure: TimeoutFailure(),
      ),
      act: (bloc) => bloc.add(const RateHistoryRetried()),
      verify: (_) {
        verify(
          () => getRateHistory(
            const GetRateHistoryParams(currency: Currency.sar),
          ),
        ).called(1);
      },
    );

    blocTest<RateHistoryBloc, RateHistoryState>(
      'is a no-op when no currency has been selected yet',
      build: buildBloc,
      act: (bloc) => bloc.add(const RateHistoryRetried()),
      expect: () => const <RateHistoryState>[],
      verify: (_) => verifyNever(() => getRateHistory(any())),
    );
  });

  group('state derivations', () {
    test('shows the shimmer for both initial and loading', () {
      expect(const RateHistoryState().isLoading, isTrue);
      expect(
        const RateHistoryState(status: RateHistoryStatus.loading).isLoading,
        isTrue,
      );
    });

    test('a single point is not plottable', () {
      final state = RateHistoryState(
        status: RateHistoryStatus.success,
        currency: Currency.usd,
        history: Fixtures.history(pointCount: 1),
      );

      expect(state.isPlottable, isFalse);
      expect(state.isEmpty, isFalse);
    });

    test('flags a partial window without failing', () {
      final history = Fixtures.history(pointCount: 4);

      expect(history.isPartial, isTrue);
      expect(history.isPlottable, isTrue);
    });
  });
}
