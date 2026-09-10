import 'package:currency_exchange_tracker/core/error/failures.dart';

/// A success-or-[Failure] container returned by every repository and use case.
///
/// Using an explicit result type instead of throwing keeps the failure path in
/// the method signature, so BLoCs cannot forget to handle it. Dart 3 exhaustive
/// `switch` on the sealed hierarchy makes that check a compile-time one:
///
/// ```dart
/// switch (await getExchangeRates()) {
///   case Ok(:final value):  emit(Loaded(value));
///   case Err(:final failure): emit(Error(failure));
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Wraps a successful [value].
  const factory Result.ok(T value) = Ok<T>;

  /// Wraps a [failure].
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;

  bool get isErr => this is Err<T>;

  /// The value when successful, otherwise `null`.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The failure when unsuccessful, otherwise `null`.
  Failure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };

  /// Collapses both branches into a single value of type [R].
  R fold<R>(R Function(Failure failure) onErr, R Function(T value) onOk) =>
      switch (this) {
        Ok<T>(:final value) => onOk(value),
        Err<T>(:final failure) => onErr(failure),
      };

  /// Transforms the success value, preserving any failure.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Ok<R>(transform(value)),
    Err<T>(:final failure) => Err<R>(failure),
  };
}

/// Successful branch of a [Result].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok<T>, value);

  @override
  String toString() => 'Ok($value)';
}

/// Failing branch of a [Result].
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err<T>, failure);

  @override
  String toString() => 'Err($failure)';
}
