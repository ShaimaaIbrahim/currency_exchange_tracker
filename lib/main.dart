import 'dart:async';

import 'package:currency_exchange_tracker/app/app.dart';
import 'package:currency_exchange_tracker/app/app_bloc_observer.dart';
import 'package:currency_exchange_tracker/core/di/injector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  // Guarded so an uncaught async error surfaces as a report instead of
  // silently killing a zone.
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        if (kReleaseMode) {
          // Hook a crash reporter in here.
        }
      };

      Bloc.observer = const AppBlocObserver();

      // `SharedPreferences` must be ready before the first frame, otherwise
      // the cache read races the first build and the offline path flickers.
      await configureDependencies();

      runApp(const CurrencyExchangeApp());
    },
    (error, stackTrace) {
      debugPrint('Uncaught zone error: $error\n$stackTrace');
    },
  );
}
