import 'package:currency_exchange_tracker/core/usecase/use_case.dart';
import 'package:currency_exchange_tracker/core/utils/result.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rates_board.dart';
import 'package:currency_exchange_tracker/features/currency/domain/repositories/currency_repository.dart';
import 'package:equatable/equatable.dart';

/// Loads the exchange-rate board for Module 1.
class GetRatesBoard implements UseCase<RatesBoard, GetRatesBoardParams> {
  const GetRatesBoard(this._repository);

  final CurrencyRepository _repository;

  @override
  Future<Result<RatesBoard>> call(GetRatesBoardParams input) {
    return _repository.getRatesBoard(forceRefresh: input.forceRefresh);
  }
}

class GetRatesBoardParams extends Equatable {
  const GetRatesBoardParams({this.forceRefresh = false});

  /// Set by pull-to-refresh: bypass any in-memory/disk short-circuit and go
  /// to the network if one is available.
  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}
