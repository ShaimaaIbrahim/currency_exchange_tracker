import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Debug-only trace of bloc traffic.
///
/// Registered instead of scattering `print`s through the blocs, which keeps
/// business logic free of logging concerns and makes the whole trace
/// switchable from one place.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    if (kDebugMode) {
      debugPrint(
        '[${bloc.runtimeType}] ${transition.event.runtimeType} → '
        '${transition.nextState.runtimeType}',
      );
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    // An error reaching here means a handler threw rather than emitting a
    // failure state — always a defect, so it is loud even in release logs.
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'bloc',
        context: ErrorDescription('in ${bloc.runtimeType}'),
      ),
    );
    super.onError(bloc, error, stackTrace);
  }
}
