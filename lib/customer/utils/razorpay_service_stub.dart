void openRazorpay({
  required Map<String, dynamic> options,
  required Function(String paymentId) onSuccess,
  required Function(String code, String message) onFailure,
}) {
  throw UnsupportedError('Razorpay is not supported on this platform.');
}
