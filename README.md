# Currency Exchange Tracker

A Flutter app that tracks live exchange rates for five major currencies against
the **Egyptian Pound (EGP)**, with a 7-day historical chart and a full offline
cache.

Built as a product, not a demo: clean architecture, domain-driven BLoC,
categorised failures, shimmer loading, and a responsive layout that works from
a 320dp phone to a desktop window.

---

## Spec coverage

| Module | Requirement | Implementation |
|--------|-------------|----------------|
| **1** | List of USD/EUR/GBP/SAR/JPY vs EGP | `ExchangeRatesPage` + `ExchangeRatesBloc` |
| **1** | Latest + yesterday → daily change | Repository fetches both, walks back on gaps |
| **1** | Invert API quote → "1 USD = X EGP" | `CurrencyRate.fromEgpQuotes` |
| **1** | Green when EGP strengthens, red when weakens | `RateTrend` (pound-centric, not number-centric) |
| **1** | Pull-to-refresh | `RefreshIndicator` + always-scrollable physics |
| **1** | Loading / error / empty | Shimmer skeletons, `AppMessageView`, `AppEmptyView` |
| **2** | Detail screen with rate, change, date | `CurrencyDetailPage` + `RateSummaryCard` |
| **2** | 7-day line chart | `fl_chart` via `RateHistoryChart` |
| **2** | Chart shimmer (not spinner) | `RateHistoryChartShimmer` |
| **2** | Chart error handling | Inline `AppMessageView`, summary stays visible |
| **3** | Persist last fetch | `SharedPreferences` via `CurrencyLocalDataSource` |
| **3** | Offline → show cache + timestamp | `OfflineNotice` + `RatesSource.cache` |
| **3** | Reconnect → auto refresh | `ConnectivityCubit` → `ExchangeRatesConnectionRestored` |

---

## Why BLoC

The evaluation criteria explicitly ask for **domain-driven BLoC separation**,
and the project size lands in the sweet spot for it:

- Two screens, three independent concerns (board / history / connectivity)
- Clear events the UI can fire and states it can render exhaustively
- Each BLoC depends only on use cases — unit-testable with `bloc_test` and
  zero HTTP/storage fakes
- `droppable` / `restartable` transformers (from `bloc_concurrency`) encode
  the concurrency policy in one line

Alternatives considered and rejected for this size:

| Option | Why not |
|--------|---------|
| Riverpod | Excellent, but the brief asks for BLoC specifically |
| Provider + `ChangeNotifier` | No event/state vocabulary, weaker test story |
| Cubit-only | Fine for connectivity; too weak once refresh / restore / retry are distinct intents |

---

## Architecture

```
lib/
├── main.dart / app/                  # bootstrap, theme, bloc observer
├── core/
│   ├── constants/                    # windows, timeouts, cache keys
│   ├── di/                           # get_it object graph
│   ├── error/                        # AppException ↔ Failure
│   ├── extensions/                   # DateTime helpers
│   ├── network/                      # Dio client, endpoints, connectivity
│   ├── responsive/                   # breakpoints, builders, center
│   ├── router/                       # go_router
│   ├── theme/                        # colours, spacing, ThemeData
│   ├── usecase/                      # UseCase<Out, In>
│   ├── utils/                        # Result, RateFormatter
│   └── widgets/                      # shimmer, message views
└── features/currency/
    ├── data/
    │   ├── datasources/              # remote (API) + local (prefs)
    │   ├── mappers/                  # exception → failure
    │   ├── models/                   # RatesSnapshotModel
    │   └── repositories/             # CurrencyRepositoryImpl
    ├── domain/
    │   ├── entities/                 # Currency, CurrencyRate, RatesBoard…
    │   ├── repositories/             # abstract CurrencyRepository
    │   └── usecases/                 # GetRatesBoard, GetRateHistory…
    └── presentation/
        ├── bloc/                     # 3 BLoCs, one concern each
        └── view/                     # pages + widgets
```

**Dependency rule:** `presentation → domain ← data`. The domain never imports
Flutter, Dio or SharedPreferences.

**Error flow:**

```
DioException
   └─ DioExceptionMapper → AppException
         └─ FailureMapper → Failure
               └─ Result.err → BLoC state → AppMessageView
```

---

## Responsive design

Rules live in [`.cursor/rules/responsive-design.mdc`](.cursor/rules/responsive-design.mdc)
and are enforced in code by:

- `AppBreakpoints` + `WindowSize`
- `context.responsive(...)` / `ResponsiveBuilder`
- `ResponsiveCenter` / `ResponsiveSliverCenter` (caps content width)
- `AppSpacing` tokens (no magic padding numbers)
- List on phone → grid on tablet/desktop
- Shimmer skeletons that reserve real layout space
- Text-scale clamp `0.85…1.6`, `FittedBox` on critical numbers

---

## Getting started

```bash
cd ~/currency_exchange_tracker
flutter pub get
flutter run
```

### Tests

```bash
flutter test
```

88 tests covering:

- Rate inversion & EGP-centric trend (the highest-value domain logic)
- Snapshot JSON parsing & cache round-trip
- Repository online / offline / gap-walking / fallback policy
- `ExchangeRatesBloc` & `RateHistoryBloc` (incl. concurrency transformers)
- Widget states: loading, success, empty, error, offline, responsive

---

## API

Open, keyless currency feed:

| Purpose | URL |
|---------|-----|
| Latest | `https://latest.currency-api.pages.dev/v1/currencies/egp.json` |
| Historical | `https://{YYYY-MM-DD}.currency-api.pages.dev/v1/currencies/egp.json` |

The feed returns **foreign units per 1 EGP**. The app inverts once in the
domain so every other layer works with **EGP per 1 foreign unit**.

---

## AI usage

See [`AI_USAGE.md`](AI_USAGE.md) for the end-to-end log of how AI was used on
this project (prompts, outputs, accept / edit / reject decisions).
