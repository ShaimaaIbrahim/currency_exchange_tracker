import 'package:currency_exchange_tracker/core/constants/app_strings.dart';
import 'package:currency_exchange_tracker/core/error/failures.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rates_board.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/connectivity/connectivity_cubit.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/exchange_rates/exchange_rates_bloc.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/pages/exchange_rates_page.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/offline_notice.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/rate_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  late MockExchangeRatesBloc ratesBloc;
  late MockConnectivityCubit connectivityCubit;

  setUp(() {
    ratesBloc = MockExchangeRatesBloc();
    connectivityCubit = MockConnectivityCubit();
    when(() => connectivityCubit.state)
        .thenReturn(const ConnectivityState(status: ConnectivityStatus.online));
  });

  Future<void> pumpPage(WidgetTester tester, {Size? surfaceSize}) {
    return tester.pumpApp(
      const ExchangeRatesPage(),
      exchangeRatesBloc: ratesBloc,
      connectivityCubit: connectivityCubit,
      surfaceSize: surfaceSize ?? const Size(390, 844),
    );
  }

  group('loading state', () {
    testWidgets('shows shimmer, not a spinner', (tester) async {
      when(() => ratesBloc.state).thenReturn(
        const ExchangeRatesState(status: ExchangeRatesStatus.loading),
      );

      await pumpPage(tester);

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(RateCard), findsNothing);
    });

    testWidgets('reserves one skeleton per tracked currency', (tester) async {
      when(() => ratesBloc.state).thenReturn(
        const ExchangeRatesState(status: ExchangeRatesStatus.loading),
      );

      await pumpPage(tester);

      expect(
        find.byType(RateCardSkeleton),
        findsNWidgets(Currency.values.length),
      );
    });
  });

  group('success state', () {
    testWidgets('renders one card per rate', (tester) async {
      final board = Fixtures.board(
        rates: [
          Fixtures.usdRate(),
          Fixtures.usdRate(egpPerUnit: 60, previousEgpPerUnit: 61),
        ],
      );
      when(() => ratesBloc.state).thenReturn(
        ExchangeRatesState(status: ExchangeRatesStatus.success, board: board),
      );

      await pumpPage(tester);

      expect(find.byType(RateCard), findsNWidgets(2));
    });

    testWidgets('shows the currency name and the inverted rate', (
      tester,
    ) async {
      when(() => ratesBloc.state).thenReturn(
        ExchangeRatesState(
          status: ExchangeRatesStatus.success,
          board: Fixtures.board(rates: [Fixtures.usdRate()]),
        ),
      );

      await pumpPage(tester);

      expect(find.text('US Dollar'), findsOneWidget);
      expect(find.text('USD/EGP'), findsOneWidget);
      expect(find.text('50.00'), findsOneWidget);
    });

    testWidgets('does not show the offline notice for network data', (
      tester,
    ) async {
      when(() => ratesBloc.state).thenReturn(
        ExchangeRatesState(
          status: ExchangeRatesStatus.success,
          board: Fixtures.board(),
        ),
      );

      await pumpPage(tester);

      expect(find.byType(OfflineNotice), findsNothing);
    });
  });

  group('offline / cached state', () {
    testWidgets('shows the cached-data notice with a relative timestamp', (
      tester,
    ) async {
      when(
        () => connectivityCubit.state,
      ).thenReturn(const ConnectivityState(status: ConnectivityStatus.offline));
      when(() => ratesBloc.state).thenReturn(
        ExchangeRatesState(
          status: ExchangeRatesStatus.success,
          board: Fixtures.board(
            source: RatesSource.cache,
            retrievedAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ),
      );

      await pumpPage(tester);

      expect(find.byType(OfflineNotice), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(OfflineNotice),
          matching: find.textContaining('3 hours ago'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the offline chip in the app bar', (tester) async {
      when(
        () => connectivityCubit.state,
      ).thenReturn(const ConnectivityState(status: ConnectivityStatus.offline));
      when(() => ratesBloc.state).thenReturn(
        ExchangeRatesState(
          status: ExchangeRatesStatus.success,
          board: Fixtures.board(source: RatesSource.cache),
        ),
      );

      await pumpPage(tester);

      expect(find.byType(OfflineChip), findsOneWidget);
    });
  });

  group('failure state', () {
    testWidgets('shows a friendly message and a retry action', (tester) async {
      when(() => ratesBloc.state).thenReturn(
        const ExchangeRatesState(
          status: ExchangeRatesStatus.failure,
          failure: OfflineFailure(),
        ),
      );

      await pumpPage(tester);

      expect(find.text(AppStrings.failureOfflineTitle), findsOneWidget);
      expect(find.text(AppStrings.tryAgain), findsOneWidget);
    });

    testWidgets('retry dispatches a refresh', (tester) async {
      when(() => ratesBloc.state).thenReturn(
        const ExchangeRatesState(
          status: ExchangeRatesStatus.failure,
          failure: TimeoutFailure(),
        ),
      );

      await pumpPage(tester);
      await tester.tap(find.text(AppStrings.tryAgain));

      verify(() => ratesBloc.add(const ExchangeRatesRefreshRequested()))
          .called(1);
    });

    testWidgets('hides retry for a failure that cannot succeed', (
      tester,
    ) async {
      // `ParsingFailure` is a contract bug; retrying the same request cannot
      // help, so offering the button would be a lie.
      when(() => ratesBloc.state).thenReturn(
        const ExchangeRatesState(
          status: ExchangeRatesStatus.failure,
          failure: ParsingFailure(),
        ),
      );

      await pumpPage(tester);

      expect(find.text(AppStrings.tryAgain), findsNothing);
    });
  });

  group('empty state', () {
    testWidgets('is distinct from both loading and error', (tester) async {
      when(() => ratesBloc.state).thenReturn(
        ExchangeRatesState(
          status: ExchangeRatesStatus.success,
          board: Fixtures.board(rates: const []),
        ),
      );

      await pumpPage(tester);

      expect(find.text(AppStrings.emptyRatesTitle), findsOneWidget);
      expect(find.byType(Shimmer), findsNothing);
      expect(find.byType(RateCard), findsNothing);
    });
  });

  group('pull to refresh', () {
    testWidgets('dispatches a refresh from the app-bar button', (tester) async {
      when(() => ratesBloc.state).thenReturn(
        ExchangeRatesState(
          status: ExchangeRatesStatus.success,
          board: Fixtures.board(),
        ),
      );

      await pumpPage(tester);
      await tester.tap(find.byTooltip(AppStrings.refreshRatesTooltip));
      await tester.pump();

      verify(() => ratesBloc.add(const ExchangeRatesRefreshRequested()))
          .called(1);
    });

    testWidgets('keeps the scroll view always-scrollable on error', (
      tester,
    ) async {
      // The error state is exactly when a user wants to pull to retry, so the
      // scroll view must remain draggable even when its content is short.
      when(() => ratesBloc.state).thenReturn(
        const ExchangeRatesState(
          status: ExchangeRatesStatus.failure,
          failure: TimeoutFailure(),
        ),
      );

      await pumpPage(tester);

      final scrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());
    });
  });

  group('responsive layout', () {
    testWidgets('uses a single column on a phone', (tester) async {
      when(() => ratesBloc.state).thenReturn(
        ExchangeRatesState(
          status: ExchangeRatesStatus.success,
          board: Fixtures.board(),
        ),
      );

      await pumpPage(tester, surfaceSize: const Size(390, 844));

      expect(find.byType(RateCard), findsOneWidget);
      expect(find.byType(SliverGrid), findsNothing);
    });

    testWidgets('switches to a grid on a tablet', (tester) async {
      when(() => ratesBloc.state).thenReturn(
        ExchangeRatesState(
          status: ExchangeRatesStatus.success,
          board: Fixtures.board(),
        ),
      );

      // 900dp is `medium` (2 columns). 1024dp is already `expanded` (3).
      await pumpPage(tester, surfaceSize: const Size(900, 1200));

      expect(find.byType(SliverGrid), findsOneWidget);
      expect(find.byType(RateCard), findsOneWidget);
    });

    testWidgets('renders without overflow at the maximum text scale', (
      tester,
    ) async {
      when(() => ratesBloc.state).thenReturn(
        ExchangeRatesState(
          status: ExchangeRatesStatus.success,
          board: Fixtures.board(),
        ),
      );

      await tester.pumpApp(
        const ExchangeRatesPage(),
        exchangeRatesBloc: ratesBloc,
        connectivityCubit: connectivityCubit,
        surfaceSize: const Size(390, 844),
        textScale: 1.6,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(RateCard), findsOneWidget);
    });
  });
}
