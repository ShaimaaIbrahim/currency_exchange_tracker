import 'package:currency_exchange_tracker/core/utils/result.dart';
import 'package:equatable/equatable.dart';

/// A single application operation, invoked as a callable object.
///
/// Keeping one class per operation means a BLoC declares exactly the
/// capabilities it needs, which is what makes the BLoCs independently
/// testable — a fake use case is a two-line override.
abstract interface class UseCase<Output, Input> {
  Future<Result<Output>> call(Input input);
}

/// Marker for use cases that need no input.
final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const [];
}
