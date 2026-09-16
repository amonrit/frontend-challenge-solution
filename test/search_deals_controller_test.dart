import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/search/search_deals_controller.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/repository/deal_repo.dart';
import 'package:rescu/service/fake_api_service.dart';

class _ControlledDealRepo extends DealRepo {
  _ControlledDealRepo() : super(api: FakeApiService());

  final _responses = <String, Completer<List<DealModel>>>{};

  @override
  Future<List<DealModel>> search(String query) {
    return _responses.putIfAbsent(query, Completer<List<DealModel>>.new).future;
  }

  void complete(String query, List<DealModel> deals) {
    _responses[query]!.complete(deals);
  }
}

DealModel _deal(int id, String name) {
  return DealModel(
    id: id,
    name: name,
    description: '',
    imageUrl: '',
    originalPrice: 100,
    price: 50,
    currencyCode: 'THB',
    quantityLeft: 1,
    storeId: id,
    storeName: 'Test store',
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

void main() {
  test('keeps latest results when an older search finishes last', () async {
    final repo = _ControlledDealRepo();
    final controller = SearchDealsController(dealRepo: repo);
    final sushi = _deal(1, 'Sushi');
    final bakery = _deal(2, 'Bakery');

    controller.onQueryChanged('sushi');
    controller.onQueryChanged('bakery');

    repo.complete('bakery', [bakery]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.results, [bakery]);

    repo.complete('sushi', [sushi]);
    await Future<void>.delayed(Duration.zero);

    expect(controller.results, [bakery]);
  });
}
