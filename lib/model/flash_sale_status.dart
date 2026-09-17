enum FlashSaleState { notFlashSale, active, expired }

/// Immutable flash-sale state derived from an end instant and a supplied clock.
class FlashSaleStatus {
  const FlashSaleStatus._({
    required this.state,
    required this.remaining,
    required this.label,
  });

  factory FlashSaleStatus.fromEnd(
    DateTime? endsAt, {
    required DateTime now,
  }) {
    if (endsAt == null) {
      return const FlashSaleStatus._(
        state: FlashSaleState.notFlashSale,
        remaining: null,
        label: null,
      );
    }

    final remaining = endsAt.difference(now);
    if (remaining <= Duration.zero) {
      return const FlashSaleStatus._(
        state: FlashSaleState.expired,
        remaining: Duration.zero,
        label: 'Expired',
      );
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    final label = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:'
            '${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}';

    return FlashSaleStatus._(
      state: FlashSaleState.active,
      remaining: remaining,
      label: label,
    );
  }

  final FlashSaleState state;
  final Duration? remaining;
  final String? label;

  bool get isActive => state == FlashSaleState.active;
  bool get isExpired => state == FlashSaleState.expired;
}
