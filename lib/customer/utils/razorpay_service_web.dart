import 'dart:js' as js;

void openRazorpay({
  required Map<String, dynamic> options,
  required Function(String paymentId) onSuccess,
  required Function(String code, String message) onFailure,
}) {
  final jsOptions = js.JsObject.jsify(options);
  js.context.callMethod('openRazorpayCheckout', [
    jsOptions,
    onSuccess,
    (code, message) {
      onFailure(code?.toString() ?? '', message?.toString() ?? '');
    },
  ]);
}
