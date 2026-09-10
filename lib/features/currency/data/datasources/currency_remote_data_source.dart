import 'package:currency_exchange_tracker/core/error/exceptions.dart';
import 'package:currency_exchange_tracker/core/network/api_client.dart';
import 'package:currency_exchange_tracker/core/network/api_endpoints.dart';
import 'package:currency_exchange_tracker/features/currency/data/models/rates_snapshot_model.dart';

/// Reads rate snapshots from the currency-api feed.
abstract interface class CurrencyRemoteDataSource {
  /// Today's snapshot.
  Future<RatesSnapshotModel> fetchLatest();

  /// The snapshot published on [date].
  ///
  /// Throws [RatesNotPublishedException] when the feed has nothing for that
  /// day, which callers treat as "skip this point", not as an error.
  Future<RatesSnapshotModel> fetchByDate(DateTime date);
}

class CurrencyRemoteDataSourceImpl implements CurrencyRemoteDataSource {
  const CurrencyRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<RatesSnapshotModel> fetchLatest() async {
    final json = await _client.getJson(ApiEndpoints.latest());
    return RatesSnapshotModel.fromJson(json);
  }

  @override
  Future<RatesSnapshotModel> fetchByDate(DateTime date) async {
    final json = await _client.getJson(
      ApiEndpoints.historical(date),
      requestedDate: date,
    );
    return RatesSnapshotModel.fromJson(json);
  }
}
