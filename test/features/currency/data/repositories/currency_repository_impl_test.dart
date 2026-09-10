import 'package:currency_exchange_tracker/core/error/exceptions.dart';
import 'package:currency_exchange_tracker/core/error/failures.dart';
import 'package:currency_exchange_tracker/core/network/network_info.dart';
import 'package:currency_exchange_tracker/core/utils/result.dart';
import 'package:currency_exchange_tracker/features/currency/data/datasources/currency_local_data_source.dart';
import 'package:currency_exchange_tracker/features/currency/data/datasources/currency_remote_data_source.dart';
import 'package:currency_exchange_tracker/features/currency/data/models/rates_snapshot_model.dart';
import 'package:currency_exchange_tracker/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rate_trend.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rates_board.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';

class _MockRemote extends Mock implements CurrencyRemoteDataSource {}

class _MockLocal extends Mock implements CurrencyLocalDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late _MockNetworkInfo networkInfo;
  late CurrencyRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(Fixtures.latestSnapshot()));

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    networkInfo = _MockNetworkInfo();
    repository = CurrencyRepositoryImpl(
      remote: remote,
      local: local,
      networkInfo: networkInfo,
      // Frozen clock: assertions about "yesterday" must not depend on when
      // the suite runs.
      clock: () => Fixtures.now,
    );

    when(
      () => local.cacheSnapshots(
        latest: any(named: 'latest'),
        previous: any(named: 'previous'),
        cachedAt: any(named: 'cachedAt'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => local.cacheHistory(
        currencyCode: any(named: 'currencyCode'),
        snapshots: any(named: 'snapshots'),
      ),
    ).thenAnswer((_) async {});
  });

  void goOnline() =>
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);

  void goOffline() =>
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

  group('getRatesBoard — online', () {
    setUp(goOnline);

    test('returns a network-sourced board with all five currencies', () async {
      when(remote.fetchLatest)
          .thenAnswer((_) async => Fixtures.latestSnapshot());
      when(() => remote.fetchByDate(any()))
          .thenAnswer((_) async => Fixtures.previousSnapshot());

      final result = await repository.getRatesBoard();

      final board = (result as Ok<RatesBoard>).value;
      expect(board.source, RatesSource.network);
      expect(board.rates, hasLength(Currency.values.length));
    });

    test('inverts quotes and derives the pound-centric trend', () async {
      when(remote.fetchLatest)
          .thenAnswer((_) async => Fixtures.latestSnapshot());
      when(() => remote.fetchByDate(any()))
          .thenAnswer((_) async => Fixtures.previousSnapshot());

      final board = (await repository.getRatesBoard()).valueOrNull!;
      final usd = board.rateFor(Currency.usd)!;

      // 0.02 -> 50 EGP today, 0.025 -> 40 EGP yesterday: the pound weakened.
      expect(usd.egpPerUnit, 50);
      expect(usd.previousEgpPerUnit, 40);
      expect(usd.trend, RateTrend.egpWeaker);
    });

    test('writes through to the cache on success', () async {
      when(remote.fetchLatest)
          .thenAnswer((_) async => Fixtures.latestSnapshot());
      when(() => remote.fetchByDate(any()))
          .thenAnswer((_) async => Fixtures.previousSnapshot());

      await repository.getRatesBoard();

      verify(
        () => local.cacheSnapshots(
          latest: any(named: 'latest'),
          previous: any(named: 'previous'),
          cachedAt: any(named: 'cachedAt'),
        ),
      ).called(1);
    });

    test('still succeeds when the cache write fails', () async {
      // Caching is best-effort: a full disk must not turn a good fetch into
      // an error screen.
      when(remote.fetchLatest)
          .thenAnswer((_) async => Fixtures.latestSnapshot());
      when(() => remote.fetchByDate(any()))
          .thenAnswer((_) async => Fixtures.previousSnapshot());
      when(
        () => local.cacheSnapshots(
          latest: any(named: 'latest'),
          previous: any(named: 'previous'),
          cachedAt: any(named: 'cachedAt'),
        ),
      ).thenThrow(const CacheException());

      final result = await repository.getRatesBoard();

      expect(result.isOk, isTrue);
    });

    test(
      'walks back past a gap in the feed to find a comparison day',
      () async {
        // The feed skips days. Yesterday 404s, so the day before is used and
        // the change column survives.
        when(remote.fetchLatest)
            .thenAnswer((_) async => Fixtures.latestSnapshot());

        final twoDaysAgo = Fixtures.today.subtract(const Duration(days: 2));
        when(() => remote.fetchByDate(Fixtures.yesterday))
            .thenThrow(RatesNotPublishedException(Fixtures.yesterday));
        when(
          () => remote.fetchByDate(twoDaysAgo),
        ).thenAnswer((_) async => Fixtures.previousSnapshot(date: twoDaysAgo));

        final board = (await repository.getRatesBoard()).valueOrNull!;

        expect(board.rateFor(Currency.usd)!.previousAsOf, twoDaysAgo);
      },
    );

    test(
      'returns rates without a change when no previous day exists',
      () async {
        when(remote.fetchLatest)
            .thenAnswer((_) async => Fixtures.latestSnapshot());
        when(() => remote.fetchByDate(any()))
            .thenThrow(RatesNotPublishedException(Fixtures.yesterday));

        final board = (await repository.getRatesBoard()).valueOrNull!;
        final usd = board.rateFor(Currency.usd)!;

        expect(usd.egpPerUnit, 50);
        expect(usd.hasChange, isFalse);
      },
    );

    test(
      'drops a currency the feed omitted rather than showing zero',
      () async {
        when(remote.fetchLatest).thenAnswer(
          (_) async => RatesSnapshotModel(
            date: Fixtures.today,
            quotes: const {'usd': 0.02, 'eur': 0.0125},
          ),
        );
        when(() => remote.fetchByDate(any()))
            .thenThrow(RatesNotPublishedException(Fixtures.yesterday));

        final board = (await repository.getRatesBoard()).valueOrNull!;

        expect(board.rates.map((rate) => rate.currency), [
          Currency.usd,
          Currency.eur,
        ]);
      },
    );

    test('falls back to cache when the fetch fails but cache exists', () async {
      when(remote.fetchLatest).thenThrow(const ServerException());
      when(local.readSnapshots).thenAnswer(
        (_) async => CachedSnapshots(
          latest: Fixtures.latestSnapshot(),
          previous: Fixtures.previousSnapshot(),
          cachedAt: Fixtures.now.subtract(const Duration(hours: 2)),
        ),
      );

      final result = await repository.getRatesBoard();
      final board = (result as Ok<RatesBoard>).value;

      expect(board.source, RatesSource.cache);
      expect(
        board.retrievedAt,
        Fixtures.now.subtract(const Duration(hours: 2)),
      );
    });

    test('surfaces the network failure when there is no cache', () async {
      when(remote.fetchLatest).thenThrow(const ServerException());
      when(local.readSnapshots).thenThrow(const CacheMissException());

      final result = await repository.getRatesBoard();

      expect((result as Err<RatesBoard>).failure, isA<ServerFailure>());
    });

    test('maps a timeout to TimeoutFailure', () async {
      when(remote.fetchLatest).thenThrow(const RequestTimeoutException());
      when(local.readSnapshots).thenThrow(const CacheMissException());

      final result = await repository.getRatesBoard();

      expect((result as Err<RatesBoard>).failure, isA<TimeoutFailure>());
    });
  });

  group('getRatesBoard — offline', () {
    setUp(goOffline);

    test(
      'serves cached data marked as cached, without touching the network',
      () async {
        when(local.readSnapshots).thenAnswer(
          (_) async => CachedSnapshots(
            latest: Fixtures.latestSnapshot(),
            previous: Fixtures.previousSnapshot(),
            cachedAt: Fixtures.now.subtract(const Duration(hours: 3)),
          ),
        );

        final board = (await repository.getRatesBoard()).valueOrNull!;

        expect(board.isFromCache, isTrue);
        expect(board.rates, isNotEmpty);
        verifyNever(remote.fetchLatest);
      },
    );

    test('reports the cache timestamp, not the publication date', () async {
      // The offline banner answers "how stale is this?", which is about when
      // we fetched, not when the feed published.
      final fetchedAt = Fixtures.now.subtract(const Duration(hours: 5));
      when(local.readSnapshots).thenAnswer(
        (_) async => CachedSnapshots(
          latest: Fixtures.latestSnapshot(),
          cachedAt: fetchedAt,
        ),
      );

      final board = (await repository.getRatesBoard()).valueOrNull!;

      expect(board.retrievedAt, fetchedAt);
      expect(board.publishedAt, Fixtures.today);
    });

    test('fails with OfflineFailure when the cache is empty', () async {
      when(local.readSnapshots).thenThrow(const CacheMissException());

      final result = await repository.getRatesBoard();

      expect((result as Err<RatesBoard>).failure, isA<OfflineFailure>());
    });
  });

  group('getRateHistory', () {
    setUp(goOnline);

    test('requests one call per day in the window', () async {
      when(() => remote.fetchByDate(any())).thenAnswer(
        (invocation) async => Fixtures.latestSnapshot(
          date: invocation.positionalArguments.first as DateTime,
        ),
      );

      await repository.getRateHistory(currency: Currency.usd, days: 7);

      verify(() => remote.fetchByDate(any())).called(7);
    });

    test('returns points sorted oldest first', () async {
      when(() => remote.fetchByDate(any())).thenAnswer(
        (invocation) async => Fixtures.latestSnapshot(
          date: invocation.positionalArguments.first as DateTime,
        ),
      );

      final history = (await repository.getRateHistory(currency: Currency.usd))
          .valueOrNull!;

      final dates = history.points.map((point) => point.date).toList();
      expect(dates, orderedEquals(List.of(dates)..sort()));
      expect(history.points.first.egpPerUnit, 50);
    });

    test('returns a partial series when the feed skipped days', () async {
      // A 5-point chart is far more useful than an error, so partial data is
      // a success with `isPartial` set.
      var call = 0;
      when(() => remote.fetchByDate(any())).thenAnswer((invocation) async {
        call++;
        if (call <= 2) {
          throw RatesNotPublishedException(
            invocation.positionalArguments.first as DateTime,
          );
        }
        return Fixtures.latestSnapshot(
          date: invocation.positionalArguments.first as DateTime,
        );
      });

      final history = (await repository.getRateHistory(currency: Currency.usd))
          .valueOrNull!;

      expect(history.points, hasLength(5));
      expect(history.isPartial, isTrue);
      expect(history.requestedDays, 7);
    });

    test('caches the fetched window', () async {
      when(() => remote.fetchByDate(any())).thenAnswer(
        (invocation) async => Fixtures.latestSnapshot(
          date: invocation.positionalArguments.first as DateTime,
        ),
      );

      await repository.getRateHistory(currency: Currency.usd);

      verify(
        () => local.cacheHistory(
          currencyCode: 'USD',
          snapshots: any(named: 'snapshots'),
        ),
      ).called(1);
    });

    test('falls back to cached history when every day fails', () async {
      when(() => remote.fetchByDate(any()))
          .thenThrow(const ConnectionException());
      when(() => local.readHistory('USD')).thenAnswer(
        (_) async => [
          Fixtures.latestSnapshot(date: Fixtures.yesterday),
          Fixtures.latestSnapshot(),
        ],
      );

      final history = (await repository.getRateHistory(currency: Currency.usd))
          .valueOrNull!;

      expect(history.points, hasLength(2));
    });

    test(
      'fails with NoDataFailure when nothing is available anywhere',
      () async {
        when(() => remote.fetchByDate(any()))
            .thenThrow(const ConnectionException());
        when(() => local.readHistory(any())).thenAnswer((_) async => const []);

        final result = await repository.getRateHistory(currency: Currency.usd);

        expect(result.failureOrNull, isA<NoDataFailure>());
      },
    );

    test(
      'fails when the tracked currency is absent from every snapshot',
      () async {
        when(() => remote.fetchByDate(any())).thenAnswer(
          (invocation) async => RatesSnapshotModel(
            date: invocation.positionalArguments.first as DateTime,
            quotes: const {'aed': 0.07},
          ),
        );

        final result = await repository.getRateHistory(currency: Currency.usd);

        expect(result.failureOrNull, isA<NoDataFailure>());
      },
    );

    group('offline', () {
      setUp(goOffline);

      test('serves cached history without hitting the network', () async {
        when(() => local.readHistory('USD')).thenAnswer(
          (_) async => [
            Fixtures.latestSnapshot(date: Fixtures.yesterday),
            Fixtures.latestSnapshot(),
          ],
        );

        final result = await repository.getRateHistory(currency: Currency.usd);

        expect(result.isOk, isTrue);
        verifyNever(() => remote.fetchByDate(any()));
      });

      test('fails with OfflineFailure when no history was cached', () async {
        when(() => local.readHistory(any())).thenAnswer((_) async => const []);

        final result = await repository.getRateHistory(currency: Currency.usd);

        expect(result.failureOrNull, isA<OfflineFailure>());
      });
    });
  });
}
