# AI Usage Log

This document records how AI (Cursor / Claude) was used to build the
**Currency Exchange Tracker**. Using AI is expected for this assessment;
what matters is the judgment applied to its output.

Timestamps are approximate wall-clock times on 2026-09-09 (Asia/Riyadh).
They line up with the commit history in this repository.

---

## Session overview

| Phase | Approx. time | Outcome |
|-------|--------------|---------|
| Spec reading & plan | 15:02 | Accepted architecture (Clean + feature-first BLoC) |
| Project scaffold | 15:05 | Accepted `flutter create` output as-is |
| Core layer | 15:10–15:40 | Accepted with edits (exception naming, Result equality) |
| Domain + data | 15:40–16:20 | Accepted; edited rate-inversion comments for clarity |
| Presentation / UI | 16:20–17:10 | Heavily edited — layout overflow, fl_chart API drift |
| Tests | 17:10–17:40 | Edited until green (concurrency delays, finder fixes) |
| Docs & rules | 17:40–17:55 | Accepted with light edits |

---

## Meaningful prompts

### 1. Initial request — build the whole app from the PDF

**Prompt (paraphrased):**
> Create a new Flutter project from this assessment PDF exactly, with the best
> state management for the project size, full details, best structure, and
> rules for responsive design.

**Model returned:** A plan to use Clean Architecture + feature-first folders +
`flutter_bloc`, with Dio, get_it, go_router, fl_chart, shimmer,
connectivity_plus, shared_preferences. Proposed module breakdown matching
the PDF (list / detail+chart / offline).

**Decision: ACCEPTED**, with one non-negotiable constraint taken from the PDF
itself — *"State Management (Domain-driven BLoC separation)"*. Riverpod was
considered briefly and rejected because the brief names BLoC.

**Why:** The project is two screens and three concerns. BLoC gives an
event/state vocabulary that maps cleanly onto "load / refresh / reconnect /
retry", and `bloc_test` makes those intents cheap to assert. Larger than a
Cubit-only toy, smaller than a codebase that would justify code-generated
Riverpod.

---

### 2. "Take all approvals direct"

**Prompt:**
> pls take all approvals direct ?

**Model returned:** Acknowledgement and continued writing files under
`~/currency_exchange_tracker`.

**Decision: ACCEPTED.**

**Why:** Procedural. No design impact.

---

### 3. Core error model

**Prompt (implicit, via continued generation):** Design the exception/failure
layer.

**Model returned:** A sealed `AppException` hierarchy and a sealed `Failure`
hierarchy, plus a `Result<T>` type and a `FailureMapper`.

**Decision: EDITED.**

Edits made:
- Renamed the first draft's `TimeoutException` → `RequestTimeoutException` to
  avoid colliding with `dart:async.TimeoutException`.
- Made `UnexpectedFailure.cause` a public field (the private `_cause` version
  tripped `prefer_initializing_formals` without a clean fix).
- Tightened the rule that Failures carry **user-safe** copy and Exceptions
  carry **machine** detail.

**Why reject the raw draft:** A name collision with the SDK would have forced
hide/show imports forever. User-facing copy on Exceptions would have leaked
into snackbars.

---

### 4. Rate inversion & EGP-centric trend

**Prompt (implicit):** Implement "1 USD = X EGP" and the green/red rule.

**Model returned:** `CurrencyRate.fromEgpQuotes` (inverts once) and a
`RateTrend` enum with `egpStronger` / `egpWeaker` / `unchanged`.

**Decision: ACCEPTED**, and then **reinforced with tests**.

**Why:** This is the single easiest place to ship a confidently wrong UI. The
API quotes foreign-per-EGP; a rising number means the pound got *weaker*.
Encoding the direction in a named type (`RateTrend.egpWeaker`) stops every
call site from re-deriving the sign. The worked example from the PDF
(`0.019227 → ≈52.01`) is asserted in
`test/.../currency_rate_test.dart`.

---

### 5. Repository offline / gap policy

**Prompt (implicit):** Implement Modules 1 and 3's data path.

**Model returned:** `CurrencyRepositoryImpl` that (a) serves cache when
offline, (b) write-through caches on success, (c) falls back to cache when a
live fetch fails, (d) walks back up to 4 days to find a comparison snapshot.

**Decision: ACCEPTED**, with one edit — cache writes became best-effort
(`_safeCache`) so a full disk cannot turn a successful fetch into an error
screen.

**Why:** The walk-back is not in the PDF, but "yesterday" is not guaranteed
to exist in the feed. Without it, the change column would blank out every
weekend. The edit on cache writes came from reviewing the AI draft and
asking "what happens if `SharedPreferences.setString` throws?".

---

### 6. Chart shimmer (spec requirement)

**Prompt (implicit):** Chart must show shimmer, not a spinner.

**Model returned:** A `RateHistoryChartShimmer` that draws a fixed jagged
silhouette with axis gutters reserved.

**Decision: ACCEPTED.**

**Why:** Matches the letter of the spec and, more importantly, reserves the
real layout so data arrival does not jump the page. A `CircularProgressIndicator`
was never offered as an option here.

---

### 7. fl_chart API drift

**Prompt (implicit):** Build the 7-day line chart.

**Model returned:** A `LineChart` using `tooltipRoundingRadius: …`.

**Decision: EDITED.**

`flutter analyze` reported `undefined_named_parameter`. The installed
`fl_chart 1.2.0` renamed the parameter to `tooltipBorderRadius`. Fixed after
checking the package source in the pub cache.

**Why reject the raw draft:** It did not compile against the resolved
dependency. This is the classic AI failure mode — training data lags the
package.

Also added: `preventCurveOverShooting: true` and a capped
`curveSmoothness: 0.25`, because an overshooting curve invents lows that
never happened on a volatile series.

---

### 8. Responsive layout overflow

**Prompt (implicit):** Make the board responsive.

**Model returned:** Phone list / tablet grid, `ResponsiveCenter`, stacked
`RateCard` under 340dp.

**Decision: EDITED** after tests caught two real bugs:

1. `SliverAppBar` title was a two-line `Column` inside the default 56dp
   toolbar → 40px bottom overflow. Fixed with `toolbarHeight: 72` and
   ellipsis.
2. At exactly 1024dp the size class is already `expanded` (3 columns), so
   each cell was ~280dp wide, the card stacked, and
   `mainAxisExtent: 108` clipped it. Fixed by raising `mainAxisExtent` to
   160 and documenting that 1024dp ≠ "tablet 2-column".

**Why:** The AI draft was directionally right and locally wrong. Widget
tests at multiple surface sizes are what made the wrongness visible; the
fixes are human judgment on top of AI output.

---

### 9. BLoC concurrency transformers

**Prompt (implicit):** Prevent duplicate in-flight fetches / stale overwrites.

**Model returned:** `droppable()` on the board BLoC, `restartable()` on the
history BLoC, plus tests that fire two events back-to-back.

**Decision: EDITED the tests.**

The transformers were correct; the tests were not. Mocks returned
immediately, so both events finished before the transformer had anything to
drop/restart. Added a 20ms delay in the mock so the first request is still
in flight when the second arrives.

**Why:** Accepting the AI tests as-is would have given a green suite that
did not actually prove the concurrency policy. This is the judgment the
assessment is looking for.

---

### 10. Docs, README, Cursor rules

**Prompt (from the original request):** "with rules responsive design".

**Model returned:** `.cursor/rules/responsive-design.mdc` and a full README.

**Decision: ACCEPTED**, lightly tightened.

The rule file is written as an agent-facing contract (size classes, measure
the parent, cap content width, shimmer-not-spinner, checklist). The README
mirrors the PDF's evaluation criteria so a reviewer can map requirement →
file in under a minute.

---

## What was rejected outright

| Suggestion (internal) | Why rejected |
|-----------------------|--------------|
| Code-generated Freezed models for every state | Graph is small; Freezed would add build_runner cost for little gain. Equatable is enough. |
| Hive / Isar for the cache | One small JSON document; `SharedPreferences` is the right tool. |
| Fetching all 7 history days sequentially | Parallel `Future.wait` is fine — the feed has no rate limit. |
| Passing the `CurrencyRate` via `GoRouter.extra` | Breaks deep links and web refresh. Code travels in the path. |
| A single god-BLoC for list + chart + connectivity | Violates the brief's "domain-driven BLoC separation" and couples lifetimes. |

---

## Summary judgment

AI wrote the bulk of the boilerplate and a solid first architecture. Human
judgment was applied on:

1. **Domain correctness** — rate inversion and EGP-centric colouring
2. **Dependency realism** — fl_chart API rename
3. **Layout truth** — overflow at real breakpoints and text scales
4. **Test honesty** — concurrency tests that actually exercise transformers
5. **Scope discipline** — no Freezed / Hive / god-BLoC

The commits in this repository are incremental and match the phases above.
