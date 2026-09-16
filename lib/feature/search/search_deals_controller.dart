import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class SearchDealsController extends GetxController {
  final DealRepo dealRepo;

  SearchDealsController({required this.dealRepo});

  final results = <DealModel>[].obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;
  int _requestGeneration = 0;

  void onQueryChanged(String query) {
    _search(query, ++_requestGeneration);
  }

  Future<void> _search(String query, int requestGeneration) async {
    if (query.trim().isEmpty) {
      results.clear();
      isLoading.value = false;
      hasSearched.value = false;
      return;
    }
    isLoading.value = true;
    hasSearched.value = true;
    try {
      final found = await dealRepo.search(query);
      if (requestGeneration != _requestGeneration) return;
      results.assignAll(found);
    } catch (e) {
      if (requestGeneration != _requestGeneration) return;
      LogService.error('search failed', e);
    } finally {
      if (requestGeneration == _requestGeneration) {
        isLoading.value = false;
      }
    }
  }
}
