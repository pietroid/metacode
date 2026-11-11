// placeOrder: builds an order (number nextOrderNumber, the cart lines, total
// from linePrice, checkoutStore, pickup, paymentMethod, status placed,
// placedAt 'Just now'), prepends it to orders, clears the cart, increments
// nextOrderNumber, adds floor(total) stars when rewardsOn, selects order 0,
// pops checkout and pushes order. Then after 3s emits the order as
// preparing, and after 5s more as ready.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

import '../views/values/shared/line_price.dart';

Future<void> placeOrder(State state, void Function(StateDelta) emit, Core core) async {
  final List<CartLine> lines = [...state.cart];
  num total = 0;
  for (final CartLine l in lines) {
    total = total + linePrice(state.menu, l);
  }
  final Order order = Order(
    number: state.nextOrderNumber,
    lines: lines,
    total: total,
    store: state.checkoutStore,
    pickup: state.pickup,
    payment: state.paymentMethod,
    status: OrderStatus.placed,
    placedAt: 'Just now',
  );
  final List<Order> rest = [...state.orders];
  final num stars = state.rewardsOn ? state.stars + total.floor() : state.stars;
  emit(StateDelta(
    orders: [order, ...rest],
    cart: <CartLine>[],
    nextOrderNumber: state.nextOrderNumber + 1,
    stars: stars,
    selectedOrder: 0,
  ));
  await core.navigator.pop();
  core.navigator.push(Routes.order);
  await Future.delayed(const Duration(seconds: 3));
  emit(StateDelta(orders: [order.copyWith(status: OrderStatus.preparing), ...rest]));
  await Future.delayed(const Duration(seconds: 5));
  emit(StateDelta(orders: [order.copyWith(status: OrderStatus.ready), ...rest]));
}

void main() {
  test('placeOrder', () async {
    final s = await app.placeOrder(sample({'rewardsOn': true}));
    expect(s.orders.length, 3);
    expect(s.orders[0].number, 1043);
    expect(s.orders[0].status, OrderStatus.ready);
    expect(s.cart.length, 0);
    expect(s.nextOrderNumber, 1044);
    expect(s.stars, 112 + 13);
    expect(app.navigation, ['pop', 'push order']);
  });
}
