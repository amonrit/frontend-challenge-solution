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

  DealModel? _deal;
  DealModel get deal => _deal!;
  DealModel? get loadedDeal => _deal;
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
    return int.tryParse(_readRouteParameter('id') ?? '');
  }

  String? _readRouteParameter(String name) {
    final parameter = Get.parameters[name];
    if (parameter != null) return parameter;

    final currentRoute = Get.rootController.routing.current;
    return Uri.tryParse(currentRoute)?.queryParameters[name];
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

  void retry() {
    if (_routeDealId != null && !_isClosed) _loadDealById();
  }

  void _initializeLoadedDeal(DealModel loadedDeal) {
    _deal = loadedDeal;
    _quantityLeft.value = loadedDeal.quantityLeft;
    analytics.logEvent('deal_details_view', {
      'deal_id': loadedDeal.id,
      'source': _readRouteParameter('source') ?? 'unknown',
    });
    // Whenever the cart changes, re-check this deal's remaining stock so the
    // details screen never shows stale availability.
    _cartWorker?.dispose();
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
    if (_isClosed) return;
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
