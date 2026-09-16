import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/home/home_controller.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/paged_response_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/repository/deal_repo.dart';
import 'package:rescu/service/fake_api_service.dart';

class _PendingRequest {
  _PendingRequest(this.page);

  final int page;
  final completer = Completer<PagedResponseModel<DealModel>>();
}

class _ControlledHomeRepo extends DealRepo {
  _ControlledHomeRepo() : super(api: FakeApiService());

  final requests = <_PendingRequest>[];

  @override
  Future<PagedResponseModel<DealModel>> fetchDeals({int page = 1}) {
    final request = _PendingRequest(page);
    requests.add(request);
    return request.completer.future;
  }

  _PendingRequest nextRequest(int page) => requests.firstWhere((r) => r.page == page && !r.completer.isCompleted);
}

DealModel _deal(int id) {
  return DealModel(
    id: id,
    name: 'Deal $id',
    description: '',
    imageUrl: '',
    originalPrice: 100,
    price: 50,
    currencyCode: 'THB',
    quantityLeft: 1,
    storeId: id,
    storeName: 'Store $id',
    storeAddress: '',
    lat: 0,
    lng: 0,
    rating: null,
    tags: const [],
    pickupWindow: PickupWindowModel(
      start: DateTime(2026, 1, 1, 12),
      end: DateTime(2026, 1, 1, 13),
    ),
    flashSaleEndsAt: null,
  );
}

PagedResponseModel<DealModel> _page(int page, List<DealModel> items) {
  return PagedResponseModel(items: items, page: page, totalPages: 2);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('does not append an older load-more response after refresh', () async {
    final repo = _ControlledHomeRepo();
    final controller = HomeController(dealRepo: repo);

    final initialRefresh = controller.refreshDeals();
    final firstPageRequest = repo.nextRequest(1);
    firstPageRequest.completer.complete(_page(1, [_deal(1)]));
    await initialRefresh;

    final loadMore = controller.loadMore();
    expect(repo.requests.where((request) => request.page == 2), hasLength(1));

    final refresh = controller.refreshDeals();
    final refreshRequest = repo.requests.last;
    expect(refreshRequest.page, 1);
    refreshRequest.completer.complete(_page(1, [_deal(3)]));
    await refresh;

    repo.nextRequest(2).completer.complete(_page(2, [_deal(4)]));
    await loadMore;

    expect(controller.deals.map((deal) => deal.id), [3]);
    controller.onClose();
  });
}
