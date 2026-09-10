import 'package:currency_exchange_tracker/core/constants/app_strings.dart';
import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  /// `YYYY-MM-DD`, the format the API expects in its host segment.
  String toApiDate() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// Midnight, so two timestamps from the same calendar day compare equal.
  DateTime get dateOnly => DateTime(year, month, day);

  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// `9 Sep 2026`
  String toMediumDate() => DateFormat('d MMM yyyy').format(this);

  /// `Sep 9, 2026 at 3:04 PM`
  String toDateTimeLabel() =>
      DateFormat("MMM d, yyyy 'at' h:mm a").format(this);

  /// `Tue 9` — compact enough for chart x-axis labels on a phone.
  String toChartLabel() => DateFormat('E d').format(this);

  /// "just now" / "12 minutes ago" / "3 hours ago" / "2 days ago".
  ///
  /// Used by the offline banner, where an exact timestamp is less useful than
  /// a sense of how stale the numbers are.
  String toRelativeLabel({DateTime? now}) {
    final reference = now ?? DateTime.now();
    final delta = reference.difference(this);

    if (delta.inSeconds < 60) return AppStrings.justNow;
    if (delta.inMinutes < 60) {
      return AppStrings.minutesAgo(delta.inMinutes);
    }
    if (delta.inHours < 24) {
      return AppStrings.hoursAgo(delta.inHours);
    }
    if (delta.inDays < 30) {
      return AppStrings.daysAgo(delta.inDays);
    }
    return AppStrings.onDate(toMediumDate());
  }
}
