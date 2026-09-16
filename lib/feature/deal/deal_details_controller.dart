import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../service/analytics_service.dart';
import '../../service/cart_service.dart';
import '../../util/log_service.dart';

class DealDetailsController extends GetxController {
  final DealRepo dealRepo;
  final CartService cartService;
  final AnalyticsService analytics;

  DealDetailsController({
    required this.dealRepo,
    required this.cartService,
    required this.analytics,
  });

  late final DealModel deal;
  int? _routeDealId;
  int? get routeDealId => _routeDealId;

  final isLoading = false.obs;
  final errorMessage = RxnString();
  bool _isClosed = false;

  final _quantityLeft = RxnInt();
  int? get quantityLeft => _quantityLeft.value;

  Worker? _cartWorker;

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    if (argument is DealModel) {
      _initializeLoadedDeal(argument);
      return;
    }

    _routeDealId = _readRouteDealId();
    _loadDealById();
  }

  int? _readRouteDealId() {
    final parameterId = Get.parameters['id'];
    if (parameterId != null) return int.tryParse(parameterId);

    final currentRoute = Get.rootController.routing.current;
    final queryId = Uri.tryParse(currentRoute)?.queryParameters['id'];
    return int.tryParse(queryId ?? '');
  }

  Future<void> _loadDealById() async {
    final id = _routeDealId;
    if (id == null) {
      errorMessage.value = 'This deal link is invalid.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      final loadedDeal = await dealRepo.fetchById(id);
      if (_isClosed) return;
      _initializeLoadedDeal(loadedDeal);
    } catch (error) {
      if (_isClosed) return;
      LogService.error('failed to load deal $id', error);
      errorMessage.value = 'Unable to load this deal. Please try again.';
    } finally {
      if (!_isClosed) isLoading.value = false;
    }
  }

  void _initializeLoadedDeal(DealModel loadedDeal) {
    deal = loadedDeal;
    _quantityLeft.value = loadedDeal.quantityLeft;
    analytics.logEvent('deal_details_view', {
      'deal_id': loadedDeal.id,
      'source': Get.parameters['source'] ?? 'unknown',
    });
    // Whenever the cart changes, re-check this deal's remaining stock so the
    // details screen never shows stale availability.
    _cartWorker = ever(cartService.itemCount, (_) => _recheckAvailability());
  }

  @override
  void onClose() {
    _isClosed = true;
    _cartWorker?.dispose();
    super.onClose();
  }

  Future<void> _recheckAvailability() async {
    LogService.log('re-checking availability for deal ${deal.id}');
    final fresh = await dealRepo.fetchById(deal.id);
    _quantityLeft.value = fresh.quantityLeft;
  }

  void addToCart() {
    cartService.add(deal);
    Get.snackbar(
      'Added to bag',
      '${deal.name} — pick up ${deal.pickupWindow.label}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}
