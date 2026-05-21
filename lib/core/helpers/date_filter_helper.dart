import '../filters/date_filter_type.dart';
import '../models/date_range_model.dart';

class DateFilterHelper {

  static DateRangeModel getRange(
    DateFilterType type, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {

    final now = DateTime.now();

    switch (type) {

      case DateFilterType.today:
        return DateRangeModel(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );

      case DateFilterType.week:
        final start = now.subtract(Duration(days: now.weekday - 1));

        return DateRangeModel(
          start: DateTime(start.year, start.month, start.day),
          end: now,
        );

      case DateFilterType.month:
        return DateRangeModel(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );

      case DateFilterType.year:
        return DateRangeModel(
          start: DateTime(now.year, 1, 1),
          end: now,
        );

      case DateFilterType.custom:
        return DateRangeModel(
          start: customStart!,
          end: customEnd!,
        );
    }
  }
}