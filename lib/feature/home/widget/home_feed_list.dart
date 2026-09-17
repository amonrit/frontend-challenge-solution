import 'package:flutter/material.dart';

import '../../../model/deal_model.dart';
import '../../shared_widget/deal_card.dart';
import 'flash_deals_section.dart';

/// Lazily builds the Home feed while keeping the flash rail and filter header
/// in the same scrollable surface.
class HomeFeedList extends StatelessWidget {
  final List<DealModel> deals;
  final List<DealModel> flashDeals;
  final bool todayOnly;
  final ValueChanged<bool> onTodayChanged;
  final ScrollController? controller;

  const HomeFeedList({
    super.key,
    required this.deals,
    required this.flashDeals,
    required this.todayOnly,
    required this.onTodayChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final hasFlashDeals = flashDeals.isNotEmpty;
    final headerIndex = hasFlashDeals ? 1 : 0;
    final dealStartIndex = headerIndex + 1;
    final footerIndex = dealStartIndex + deals.length;

    return ListView.builder(
      controller: controller,
      itemCount: footerIndex + 1,
      itemBuilder: (context, index) {
        if (hasFlashDeals && index == 0) {
          return FlashDealsSection(deals: flashDeals);
        }
        if (index == headerIndex) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Text('Nearby deals',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                FilterChip(
                  label: const Text('Pickup today'),
                  selected: todayOnly,
                  onSelected: onTodayChanged,
                ),
              ],
            ),
          );
        }
        if (index == footerIndex) return const SizedBox(height: 24);
        return DealCard(
          deal: deals[index - dealStartIndex],
          source: 'home_feed',
          position: index - dealStartIndex,
        );
      },
    );
  }
}
