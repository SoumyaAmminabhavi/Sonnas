// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
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
