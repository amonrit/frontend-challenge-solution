/// Converts API instants into the product's Bangkok market time.
///
/// The current product has one fixed-offset market (UTC+7). Keeping the
/// conversion here gives callers one policy seam without changing the meaning
/// of the UTC instants stored by the API models.
typedef NowProvider = DateTime Function();

class BangkokTimePolicy {
  BangkokTimePolicy({NowProvider? now}) : _now = now ?? DateTime.now;

  static const _offset = Duration(hours: 7);
  final NowProvider _now;

  DateTime toMarket(DateTime instant) => instant.toUtc().add(_offset);

  DateTime get nowInMarket => toMarket(_now());

  bool isToday(DateTime instant) {
    final marketInstant = toMarket(instant);
    final marketNow = nowInMarket;
    return marketInstant.year == marketNow.year &&
        marketInstant.month == marketNow.month &&
        marketInstant.day == marketNow.day;
  }

  bool isSameMarketDate(DateTime instant, DateTime reference) {
    final marketInstant = toMarket(instant);
    final marketReference = toMarket(reference);
    return marketInstant.year == marketReference.year &&
        marketInstant.month == marketReference.month &&
        marketInstant.day == marketReference.day;
  }
}
