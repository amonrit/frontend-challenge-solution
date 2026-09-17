import '../model/reservation_model.dart';
import '../repository/order_repo.dart';

/// Narrow reservation boundary owned by the app-side cart workflow.
abstract class ReservationGateway {
  Future<ReservationModel> reserve(int dealId, {int quantity = 1});

  Future<void> release(String reservationId);
}

class OrderReservationGateway implements ReservationGateway {
  OrderReservationGateway(this._orderRepo);

  final OrderRepo _orderRepo;

  @override
  Future<ReservationModel> reserve(int dealId, {int quantity = 1}) =>
      _orderRepo.reserve(dealId, quantity: quantity);

  @override
  Future<void> release(String reservationId) =>
      _orderRepo.releaseReservation(reservationId);
}
