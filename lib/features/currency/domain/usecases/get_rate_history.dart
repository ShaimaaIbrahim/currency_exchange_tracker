import 'package:currency_exchange_tracker/core/constants/app_constants.dart';
import 'package:currency_exchange_tracker/core/usecase/use_case.dart';
import 'package:currency_exchange_tracker/core/utils/result.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/currency/domain/repositories/currency_repository.dart';
import 'package:equatable/equatable.dart';

/// Loads the trailing series that backs Module 2's line chart.
class GetRateHistory implements UseCase<RateHistory, GetRateHistoryParams> {
  const GetRateHistory(this._repository);

  final CurrencyRepository _repository;

  @override
  Future<Result<RateHistory>> call(GetRateHistoryParams input) {
    return _repository.getRateHistory(
      currency: input.currency,
      days: input.days,
    );
  }
}

class GetRateHistoryParams extends Equatable {
  const GetRateHistoryParams({
    required this.currency,
    this.days = AppConstants.historyWindowDays,
  });

  final Currency currency;
  final int days;

  @override
  List<Object?> get props => [currency, days];
}
