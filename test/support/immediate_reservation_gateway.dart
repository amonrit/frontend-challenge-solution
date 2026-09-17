import 'package:rescu/model/reservation_model.dart';
import 'package:rescu/service/reservation_gateway.dart';

class ImmediateReservationGateway implements ReservationGateway {
  int _nextId = 0;

  @override
  Future<ReservationModel> reserve(int dealId, {int quantity = 1}) async =>
      ReservationModel(
        id: 'test_res_${++_nextId}',
        dealId: dealId,
        quantity: quantity,
        expiresAt: DateTime.utc(2030, 1, 1),
      );

  @override
  Future<void> release(String reservationId) async {}
}
