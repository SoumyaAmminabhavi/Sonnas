import 'dart:js_interop';

@JS('getOrderConfirmedNumber')
external JSString _getOrderConfirmedNumber();

@JS('getOrderConfirmedAmount')
external JSString _getOrderConfirmedAmount();

@JS('clearOrderConfirmedNumber')
external void _clearOrderConfirmedNumber();

@JS('setPendingOrder')
external void _setPendingOrder(JSString orderNumber, JSString amount);

String getOrderConfirmedNumber() {
  return _getOrderConfirmedNumber().toDart;
}

String getOrderConfirmedAmount() {
  return _getOrderConfirmedAmount().toDart;
}

void clearOrderConfirmedNumber() {
  _clearOrderConfirmedNumber();
}

void setPendingOrder(String orderNumber, String amount) {
  _setPendingOrder(orderNumber.toJS, amount.toJS);
}
