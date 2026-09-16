import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../app_config.dart';
import '../../routes/routes.dart';
import '../shared_widget/shimmer_deal_card.dart';
import 'home_controller.dart';
import 'widget/home_feed_list.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() => _buildAppBar(context)),
      ),
      body: Obx(_buildBody),
      floatingActionButton: Obx(
        () => Visibility(
          visible: controller.scrollOffset.value > 800,
          replacement: const SizedBox.shrink(),
          child: FloatingActionButton.small(
            onPressed: controller.scrollToTop,
            child: const Icon(Icons.arrow_upward),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final offset = controller.scrollOffset.value;
    return AppBar(
      elevation: offset > 4 ? 2 : 0,
      shadowColor: Colors.black26,
      title: const Row(
        children: [
          Icon(Icons.eco, color: AppConfig.primaryGreen),
          SizedBox(width: 8),
          Text('Rescu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => Get.toNamed(Routes.search),
        ),
        IconButton(
          icon: const Icon(Icons.map_outlined),
          onPressed: () => Get.toNamed(Routes.map),
        ),
        IconButton(
          icon: const Icon(Icons.receipt_long_outlined),
          onPressed: () => Get.toNamed(Routes.orders),
        ),
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined),
          onPressed: () => Get.toNamed(Routes.cart),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'deeplink') _showDeepLinkDialog(context);
            if (value == 'analytics') Get.toNamed(Routes.analyticsDebug);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
                value: 'deeplink', child: Text('Simulate deep link…')),
            PopupMenuItem(value: 'analytics', child: Text('Analytics debug')),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (controller.isLoading.value) {
      return ListView(
        children: const [
          ShimmerDealCard(),
          ShimmerDealCard(),
          ShimmerDealCard(),
        ],
      );
    }
    return SmartRefresher(
      controller: controller.refreshController,
      enablePullDown: true,
      enablePullUp: true,
      onRefresh: controller.refreshDeals,
      onLoading: controller.loadMore,
      child: HomeFeedList(
        controller: controller.scrollController,
        deals: controller.visibleDeals,
        flashDeals: controller.flashDeals,
        todayOnly: controller.todayOnly.value,
        onTodayChanged: (value) => controller.todayOnly.value = value,
      ),
    );
  }

  void _showDeepLinkDialog(BuildContext context) {
    final textController =
        TextEditingController(text: 'rescu://open/deal?id=42&source=push');
    Get.dialog(
      AlertDialog(
        title: const Text('Simulate deep link'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            helperText: 'e.g. rescu://open/deal?id=42&source=push',
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final uri = Uri.tryParse(textController.text.trim());
              Get.back();
              if (uri == null) return;
              final route =
                  uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
              Get.toNamed(route);
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}
