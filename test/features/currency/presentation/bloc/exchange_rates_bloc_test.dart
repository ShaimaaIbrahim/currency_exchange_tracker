import 'package:bloc_test/bloc_test.dart';
import 'package:currency_exchange_tracker/core/error/failures.dart';
import 'package:currency_exchange_tracker/core/utils/result.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rates_board.dart';
import 'package:currency_exchange_tracker/features/currency/domain/usecases/get_rates_board.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/exchange_rates/exchange_rates_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';

class _MockGetRatesBoard extends Mock implements GetRatesBoard {}

void main() {
  late _MockGetRatesBoard getRatesBoard;

  setUpAll(() => registerFallbackValue(const GetRatesBoardParams()));

  setUp(() => getRatesBoard = _MockGetRatesBoard());

  ExchangeRatesBloc buildBloc() =>
      ExchangeRatesBloc(getRatesBoard: getRatesBoard);

  void whenSucceeds({RatesBoard? board}) {
    when(() => getRatesBoard(any()))
        .thenAnswer((_) async => Ok(board ?? Fixtures.board()));
  }

  void whenFails(Failure failure) {
    when(() => getRatesBoard(any()))
        .thenAnswer((_) async => Err<RatesBoard>(failure));
  }

  test('starts in the initial state', () {
    expect(buildBloc().state.status, ExchangeRatesStatus.initial);
  });

  group('ExchangeRatesRequested', () {
    blocTest<ExchangeRatesBloc, ExchangeRatesState>(
      'emits loading then success',
      setUp: whenSucceeds,
      build: buildBloc,
      act: (bloc) => bloc.add(const ExchangeRatesRequested()),
      expect: () => [
        isA<ExchangeRatesState>().having(
          (s) => s.status,
          'status',
          ExchangeRatesStatus.loading,
        ),
        isA<ExchangeRatesState>()
            .having((s) => s.status, 'status', ExchangeRatesStatus.success)
            .having((s) => s.hasRates, 'hasRates', isTrue),
      ],
    );

    blocTest<ExchangeRatesBloc, ExchangeRatesState>(
      'emits a blocking failure when the first load fails',
      setUp: () => whenFails(const OfflineFailure()),
      build: buildBloc,
      act: (bloc) => bloc.add(const ExchangeRatesRequested()),
      expect: () => [
        isA<ExchangeRatesState>().having(
          (s) => s.status,
          'status',
          ExchangeRatesStatus.loading,
        ),
        isA<ExchangeRatesState>()
            .having((s) => s.status, 'status', ExchangeRatesStatus.failure)
            .having((s) => s.failure, 'failure', isA<OfflineFailure>()),
      ],
    );

    blocTest<ExchangeRatesBloc, ExchangeRatesState>(
      'does not force a refresh on first load',
      setUp: whenSucceeds,
      build: buildBloc,
      act: (bloc) => bloc.add(const ExchangeRatesRequested()),
      verify: (_) {
        verify(
          () => getRatesBoard(const GetRatesBoardParams(forceRefresh: false)),
        ).called(1);
      },
    );

    blocTest<ExchangeRatesBloc, ExchangeRatesState>(
      'drops a duplicate request while one is already in flight',
      setUp: () {
        // Without a delay both events finish before the second is dropped.
        when(() => getRatesBoard(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return Ok(Fixtures.board());
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ExchangeRatesRequested());
        bloc.add(const ExchangeRatesRequested());
        await Future<void>.delayed(const Duration(milliseconds: 40));
      },
      verify: (_) => verify(() => getRatesBoard(any())).called(1),
    );
  });

  group('ExchangeRatesRefreshRequested', () {
    blocTest<ExchangeRatesBloc, ExchangeRatesState>(
      'keeps the old board visible while refreshing',
      setUp: whenSucceeds,
      build: buildBloc,
      seed: () => ExchangeRatesState(
        status: ExchangeRatesStatus.success,
        board: Fixtures.board(),
      ),
      act: (bloc) => bloc.add(const ExchangeRatesRefreshRequested()),
      expect: () => [
        isA<ExchangeRatesState>()
            .having((s) => s.status, 'status', ExchangeRatesStatus.refreshing)
            // The list must not collapse under the user's finger.
            .having((s) => s.hasRates, 'hasRates', isTrue),
        isA<ExchangeRatesState>().having(
          (s) => s.status,
          'status',
          ExchangeRatesStatus.success,
        ),
      ],
    );

    blocTest<ExchangeRatesBloc, ExchangeRatesState>(
      'asks the use case to force a network refresh',
      setUp: whenSucceeds,
      build: buildBloc,
      act: (bloc) => bloc.add(const ExchangeRatesRefreshRequested()),
      verify: (_) {
        verify(
          () => getRatesBoard(const GetRatesBoardParams(forceRefresh: true)),
        ).called(1);
      },
    );

    blocTest<ExchangeRatesBloc, ExchangeRatesState>(
      'reports a failed refresh non-blockingly, keeping the board',
      setUp: () => whenFails(const TimeoutFailure()),
      build: buildBloc,
      seed: () => ExchangeRatesState(
        status: ExchangeRatesStatus.success,
        board: Fixtures.board(),
      ),
      act: (bloc) => bloc.add(const ExchangeRatesRefreshRequested()),
      expect: () => [
        isA<ExchangeRatesState>().having(
          (s) => s.status,
          'status',
          ExchangeRatesStatus.refreshing,
        ),
        isA<ExchangeRatesState>()
            .having((s) => s.status, 'status', ExchangeRatesStatus.success)
            .having(
              (s) => s.refreshFailure,
              'refreshFailure',
              isA<TimeoutFailure>(),
            )
            .having((s) => s.failure, 'failure', isNull)
            .having((s) => s.hasRates, 'hasRates', isTrue),
      ],
    );

    blocTest<ExchangeRatesBloc, ExchangeRatesState>(
      'treats a pull-to-refresh with no data yet as a blocking first load',
      setUp: () => whenFails(const OfflineFailure()),
      build: buildBloc,
      act: (bloc) => bloc.add(const ExchangeRatesRefreshRequested()),
      expect: () => [
        isA<ExchangeRatesState>().having(
          (s) => s.status,
          'status',
          ExchangeRatesStatus.loading,
        ),
        isA<ExchangeRatesState>().having(
          (s) => s.status,
          'status',
          ExchangeRatesStatus.failure,
        ),
      ],
    );
  });

  group('ExchangeRatesConnectionRestored', () {
    blocTest<ExchangeRatesBloc, ExchangeRatesState>(
      'refreshes silently and swaps cached data for network data',
      setUp: () => whenSucceeds(board: Fixtures.board()),
      build: buildBloc,
      seed: () => ExchangeRatesState(
        status: ExchangeRatesStatus.success,
        board: Fixtures.board(source: RatesSource.cache),
      ),
      act: (bloc) => bloc.add(const ExchangeRatesConnectionRestored()),
      expect: () => [
        isA<ExchangeRatesState>()
            .having((s) => s.status, 'status', ExchangeRatesStatus.refreshing)
            .having((s) => s.isShowingCachedData, 'stillCached', isTrue),
        isA<ExchangeRatesState>()
            .having((s) => s.status, 'status', ExchangeRatesStatus.success)
            .having((s) => s.isShowingCachedData, 'stillCached', isFalse),
      ],
    );
  });

  group('state derivations', () {
    test('isEmpty only when a successful load produced no rates', () {
      final loaded = ExchangeRatesState(
        status: ExchangeRatesStatus.success,
        board: Fixtures.board(rates: const []),
      );

      expect(loaded.isEmpty, isTrue);
      expect(const ExchangeRatesState().isEmpty, isFalse);
    });

    test('isShowingCachedData follows the board source', () {
      expect(
        ExchangeRatesState(board: Fixtures.board(source: RatesSource.cache))
            .isShowingCachedData,
        isTrue,
      );
      expect(
        ExchangeRatesState(board: Fixtures.board()).isShowingCachedData,
        isFalse,
      );
    });

    test('copyWith can clear the refresh failure explicitly', () {
      const state = ExchangeRatesState(refreshFailure: TimeoutFailure());

      expect(state.copyWith(clearRefreshFailure: true).refreshFailure, isNull);
    });
  });
}
