import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/home/home_controller.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/paged_response_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/repository/deal_repo.dart';
import 'package:rescu/service/fake_api_service.dart';
import 'package:rescu/service/bangkok_time_policy.dart';

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

  _PendingRequest nextRequest(int page) =>
      requests.firstWhere((r) => r.page == page && !r.completer.isCompleted);
}

DealModel _deal(int id, {PickupWindowModel? pickupWindow}) {
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
    pickupWindow: pickupWindow ??
        PickupWindowModel(
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

  test('ignores a refresh response after the controller closes', () async {
    final repo = _ControlledHomeRepo();
    final controller = HomeController(dealRepo: repo);
    final refresh = controller.refreshDeals();
    final request = repo.nextRequest(1);

    controller.onClose();
    request.completer.complete(_page(1, [_deal(9)]));
    await refresh;

    expect(controller.deals, isEmpty);
  });

  test('keeps the newest result when two refreshes overlap', () async {
    final repo = _ControlledHomeRepo();
    final controller = HomeController(dealRepo: repo);

    final initial = controller.refreshDeals();
    repo.nextRequest(1).completer.complete(_page(1, [_deal(1)]));
    await initial;

    final olderRefresh = controller.refreshDeals();
    final newestRefresh = controller.refreshDeals();
    repo.requests[2].completer.complete(_page(1, [_deal(3)]));
    await newestRefresh;
    repo.requests[1].completer.complete(_page(1, [_deal(2)]));
    await olderRefresh;

    expect(controller.deals.map((deal) => deal.id), [3]);
    controller.onClose();
  });

  test('does not let a stale load-more failure corrupt refreshed state',
      () async {
    final repo = _ControlledHomeRepo();
    final controller = HomeController(dealRepo: repo);

    final initial = controller.refreshDeals();
    repo.nextRequest(1).completer.complete(_page(1, [_deal(1)]));
    await initial;

    final loadMore = controller.loadMore();
    final refresh = controller.refreshDeals();
    repo.requests.last.completer.complete(_page(1, [_deal(3)]));
    await refresh;
    repo.nextRequest(2).completer.completeError(StateError('stale failure'));
    await loadMore;

    expect(controller.deals.map((deal) => deal.id), [3]);
    controller.onClose();
  });

  test('ignores a response for a page different from the requested page',
      () async {
    final repo = _ControlledHomeRepo();
    final controller = HomeController(dealRepo: repo);

    final initial = controller.refreshDeals();
    repo.nextRequest(1).completer.complete(_page(1, [_deal(1)]));
    await initial;

    final loadMore = controller.loadMore();
    repo.nextRequest(2).completer.complete(_page(1, [_deal(9)]));
    await loadMore;

    expect(controller.deals.map((deal) => deal.id), [1]);
    final retryLoadMore = controller.loadMore();
    expect(repo.requests.where((request) => request.page == 2), hasLength(2));
    repo.requests.last.completer.complete(_page(2, [_deal(2)]));
    await retryLoadMore;
    expect(controller.deals.map((deal) => deal.id), [1, 2]);
    controller.onClose();
  });

  test('does not request another page after the final page', () async {
    final repo = _ControlledHomeRepo();
    final controller = HomeController(dealRepo: repo);

    final initial = controller.refreshDeals();
    repo.nextRequest(1).completer.complete(
          PagedResponseModel(items: [_deal(1)], page: 1, totalPages: 1),
        );
    await initial;
    await controller.loadMore();

    expect(repo.requests, hasLength(1));
    expect(controller.deals.map((deal) => deal.id), [1]);
    controller.onClose();
  });

  test('Pickup today filter uses the complete Bangkok calendar date', () {
    final repo = _ControlledHomeRepo();
    final controller = HomeController(dealRepo: repo);
    final policy = BangkokTimePolicy(
      now: () => DateTime.parse('2026-06-15T02:00:00Z'),
    );

    controller.deals.value = [
      _deal(
        1,
        pickupWindow: PickupWindowModel(
          start: DateTime.parse('2026-06-15T02:30:00Z'),
          end: DateTime.parse('2026-06-15T03:30:00Z'),
          timePolicy: policy,
        ),
      ),
      _deal(
        2,
        pickupWindow: PickupWindowModel(
          start: DateTime.parse('2026-06-16T02:30:00Z'),
          end: DateTime.parse('2026-06-16T03:30:00Z'),
          timePolicy: policy,
        ),
      ),
    ];
    controller.todayOnly.value = true;

    expect(controller.visibleDeals.map((deal) => deal.id), [1]);
    controller.onClose();
  });
}
