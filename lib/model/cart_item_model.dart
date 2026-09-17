import 'deal_model.dart';
import 'reservation_model.dart';

class CartItemModel {
  final DealModel deal;
  int quantity;

  /// Stock hold for this line item. The starter app does not reserve stock —
  /// see the "Reservations" feature task.
  ReservationModel? reservation;
  bool isReservationPending;

  CartItemModel({
    required this.deal,
    this.quantity = 1,
    this.reservation,
    this.isReservationPending = false,
  });

  num get lineTotal => deal.price * quantity;
}
