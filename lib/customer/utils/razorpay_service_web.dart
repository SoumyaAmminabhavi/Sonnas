import 'dart:js_interop';

@JS('openRazorpayCheckout')
external void _openRazorpayCheckout(JSAny? options, JSFunction onSuccess, JSFunction onFailure);

void openRazorpay({
  required Map<String, dynamic> options,
  required Function(String paymentId) onSuccess,
  required Function(String code, String message) onFailure,
}) {
  final jsOptions = options.jsify();
  
  _openRazorpayCheckout(
    jsOptions,
    ((String paymentId) {
      onSuccess(paymentId);
    }).toJS,
    ((JSAny? code, JSAny? message) {
      onFailure(
        code?.dartify()?.toString() ?? '',
        message?.dartify()?.toString() ?? ''
      );
    }).toJS,
  );
}
